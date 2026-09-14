-- Databricks SQL
USE CATALOG workspace;
USE SCHEMA anp_combustiveis_br_2022_2026;

-- Cobertura observada por fonte.
SELECT 'LOGISTICA_02' AS fonte,
       MIN(data_referencia) AS inicio,
       MAX(data_referencia) AS fim,
       COUNT(DISTINCT data_referencia) AS meses
FROM silver_venda_empresa_uf_mes
WHERE dentro_do_recorte
UNION ALL
SELECT 'SIMP_LIQUIDOS', MIN(data_referencia), MAX(data_referencia), COUNT(DISTINCT data_referencia)
FROM silver_venda_simp_liquidos
WHERE dentro_do_recorte
UNION ALL
SELECT 'PRECOS', MIN(data_referencia), MAX(data_referencia), COUNT(DISTINCT data_referencia)
FROM silver_preco_coletado
WHERE dentro_do_recorte
UNION ALL
SELECT 'VENDAS_MUNICIPAIS',
       MAKE_DATE(MIN(ano), 1, 1),
       MAKE_DATE(MAX(ano), 12, 31),
       COUNT(DISTINCT ano)
FROM silver_venda_municipio
WHERE dentro_do_recorte;

-- Volume nacional comparável: janeiro a junho de cada ano.
SELECT ano,
       produto_analitico,
       ROUND(SUM(volume_total_liquido_uf_litros) / 1000000000.0, 3) AS volume_bilhoes_litros,
       COUNT(DISTINCT uf) AS ufs_com_volume
FROM gold_mart_mercado_uf_mes
WHERE volume_disponivel
  AND mes <= 6
GROUP BY ano, produto_analitico
ORDER BY produto_analitico, ano;

-- Ranking nacional de vendedores no primeiro semestre de 2026.
WITH vendas AS (
  SELECT produto_analitico,
         vendedor,
         vendedor_chave,
         SUM(volume_liquido_litros) AS volume_litros
  FROM gold_fato_venda_empresa_uf_mes
  WHERE ano = 2026
    AND mes <= 6
    AND volume_liquido_litros > 0
  GROUP BY produto_analitico, vendedor, vendedor_chave
), ranking AS (
  SELECT *,
         100.0 * volume_litros / SUM(volume_litros) OVER (PARTITION BY produto_analitico) AS participacao_pct,
         ROW_NUMBER() OVER (PARTITION BY produto_analitico ORDER BY volume_litros DESC, vendedor) AS posicao
  FROM vendas
)
SELECT produto_analitico,
       posicao,
       vendedor,
       ROUND(volume_litros / 1000000.0, 1) AS volume_milhoes_litros,
       ROUND(participacao_pct, 2) AS participacao_pct
FROM ranking
WHERE posicao <= 12
ORDER BY produto_analitico, posicao;

-- Linhas declaradas de empresas selecionadas, sem consolidar variantes societárias.
WITH vendas AS (
  SELECT ano,
         produto_analitico,
         vendedor,
         SUM(volume_liquido_litros) AS volume_litros
  FROM gold_fato_venda_empresa_uf_mes
  WHERE mes <= 6
    AND volume_liquido_litros > 0
    AND vendedor IN (
      'VIBRA ENERGIA S.A',
      'IPIRANGA PRODUTOS DE PETRÓLEO S.A',
      'RAIZEN S.A.',
      'ALE COMBUSTIVEIS S.A.'
    )
  GROUP BY ano, produto_analitico, vendedor
), totais AS (
  SELECT ano, produto_analitico, SUM(volume_liquido_litros) AS total_litros
  FROM gold_fato_venda_empresa_uf_mes
  WHERE mes <= 6 AND volume_liquido_litros > 0
  GROUP BY ano, produto_analitico
)
SELECT v.ano,
       v.produto_analitico,
       v.vendedor,
       ROUND(v.volume_litros / 1000000.0, 1) AS volume_milhoes_litros,
       ROUND(100.0 * v.volume_litros / t.total_litros, 2) AS participacao_pct
FROM vendas v
JOIN totais t USING (ano, produto_analitico)
ORDER BY v.produto_analitico, v.vendedor, v.ano;

-- Variação da concentração entre 2022H1 e 2026H1 para todas as UFs.
WITH vendas AS (
  SELECT ano, uf, produto_analitico, vendedor_chave,
         SUM(volume_liquido_litros) AS volume_litros
  FROM gold_fato_venda_empresa_uf_mes
  WHERE ano IN (2022, 2026)
    AND mes <= 6
    AND volume_liquido_litros > 0
  GROUP BY ano, uf, produto_analitico, vendedor_chave
), participacao AS (
  SELECT *,
         volume_litros / SUM(volume_litros) OVER (PARTITION BY ano, uf, produto_analitico) AS participacao
  FROM vendas
), concentracao AS (
  SELECT ano, uf, produto_analitico,
         SUM(POWER(participacao, 2) * 10000) AS hhi,
         COUNT(*) AS vendedores_positivos,
         MAX(participacao) * 100 AS participacao_lider_pct
  FROM participacao
  GROUP BY ano, uf, produto_analitico
), comparacao AS (
  SELECT uf,
         produto_analitico,
         MAX(CASE WHEN ano = 2022 THEN hhi END) AS hhi_2022h1,
         MAX(CASE WHEN ano = 2026 THEN hhi END) AS hhi_2026h1,
         MAX(CASE WHEN ano = 2022 THEN vendedores_positivos END) AS vendedores_2022h1,
         MAX(CASE WHEN ano = 2026 THEN vendedores_positivos END) AS vendedores_2026h1,
         MAX(CASE WHEN ano = 2022 THEN participacao_lider_pct END) AS lider_2022h1_pct,
         MAX(CASE WHEN ano = 2026 THEN participacao_lider_pct END) AS lider_2026h1_pct
  FROM concentracao
  GROUP BY uf, produto_analitico
)
SELECT uf,
       produto_analitico,
       ROUND(hhi_2022h1, 0) AS hhi_2022h1,
       ROUND(hhi_2026h1, 0) AS hhi_2026h1,
       ROUND(hhi_2026h1 - hhi_2022h1, 0) AS variacao_hhi,
       vendedores_2022h1,
       vendedores_2026h1,
       ROUND(lider_2022h1_pct, 1) AS lider_2022h1_pct,
       ROUND(lider_2026h1_pct, 1) AS lider_2026h1_pct
FROM comparacao
ORDER BY produto_analitico, variacao_hhi DESC, uf;

-- Preço no primeiro semestre: mediana das UFs, sem dar peso maior a uma UF com mais coletas.
WITH preco_uf_semestre AS (
  SELECT ano,
         uf,
         produto_analitico,
         PERCENTILE_APPROX(mediana_preco, 0.50, 10000) AS mediana_preco_uf,
         SUM(qtd_coletas) AS qtd_coletas
  FROM gold_fato_preco_uf_mes
  WHERE mes <= 6
  GROUP BY ano, uf, produto_analitico
)
SELECT ano,
       produto_analitico,
       ROUND(PERCENTILE_APPROX(mediana_preco_uf, 0.50, 10000), 3) AS mediana_das_ufs,
       COUNT(DISTINCT uf) AS ufs_com_preco,
       SUM(qtd_coletas) AS qtd_coletas
FROM preco_uf_semestre
GROUP BY ano, produto_analitico
ORDER BY produto_analitico, ano;

-- Estados com maior variação de preço entre 2022H1 e 2026H1.
WITH preco_uf_semestre AS (
  SELECT ano,
         uf,
         produto_analitico,
         PERCENTILE_APPROX(mediana_preco, 0.50, 10000) AS mediana_preco_uf
  FROM gold_fato_preco_uf_mes
  WHERE ano IN (2022, 2026) AND mes <= 6
  GROUP BY ano, uf, produto_analitico
), comparacao AS (
  SELECT uf,
         produto_analitico,
         MAX(CASE WHEN ano = 2022 THEN mediana_preco_uf END) AS preco_2022h1,
         MAX(CASE WHEN ano = 2026 THEN mediana_preco_uf END) AS preco_2026h1
  FROM preco_uf_semestre
  GROUP BY uf, produto_analitico
)
SELECT uf,
       produto_analitico,
       ROUND(preco_2022h1, 2) AS preco_2022h1,
       ROUND(preco_2026h1, 2) AS preco_2026h1,
       ROUND(100.0 * (preco_2026h1 / preco_2022h1 - 1), 1) AS variacao_pct
FROM comparacao
WHERE preco_2022h1 IS NOT NULL AND preco_2026h1 IS NOT NULL
ORDER BY produto_analitico, variacao_pct DESC, uf;

-- Comparação de escopo: SIMP e Logística 02 no mesmo recorte semestral.
WITH resumo AS (
  SELECT ano,
         produto_analitico,
         SUM(volume_simp_litros) AS volume_simp_litros,
         SUM(volume_logistica_litros) AS volume_logistica_litros,
         COUNT(*) AS combinacoes_uf_mes
  FROM gold_comparacao_simp_logistica_uf_mes
  WHERE mes <= 6
  GROUP BY ano, produto_analitico
)
SELECT ano,
       produto_analitico,
       ROUND(volume_simp_litros / 1000000000.0, 3) AS simp_bilhoes_litros,
       ROUND(volume_logistica_litros / 1000000000.0, 3) AS logistica_bilhoes_litros,
       ROUND(100.0 * (volume_simp_litros - volume_logistica_litros) /
             NULLIF(volume_logistica_litros, 0), 3) AS diferenca_pct_logistica,
       combinacoes_uf_mes
FROM resumo
ORDER BY produto_analitico, ano;

-- Bloco municipal, mantido somente nos anos com publicação anual completa.
SELECT ano,
       produto_analitico,
       SUM(municipios_com_venda) AS municipios_com_venda,
       SUM(municipios_com_preco) AS municipios_com_preco,
       SUM(municipios_publicaveis) AS municipios_publicaveis,
       ROUND(100.0 * SUM(municipios_com_preco) /
             NULLIF(SUM(municipios_com_venda), 0), 2) AS cobertura_preco_pct
FROM gold_cobertura_pesquisa
WHERE ano BETWEEN 2022 AND 2024
GROUP BY ano, produto_analitico
ORDER BY produto_analitico, ano;

SELECT ano,
       grupo_reconciliacao_municipal,
       status_conciliacao,
       COUNT(*) AS combinacoes_uf
FROM gold_reconciliacao_volume_uf_ano
GROUP BY ano, grupo_reconciliacao_municipal, status_conciliacao
ORDER BY ano, grupo_reconciliacao_municipal, status_conciliacao;

-- Evidências de operação e qualidade.
SELECT lote_id, etapa, quantidade_linhas, data_execucao
FROM gold_reconciliacao_etapas
ORDER BY data_execucao DESC, etapa;

SELECT lote_id, regra_id, tabela, descricao, qtd_afetada, pct_afetada, status, data_execucao
FROM gold_resultado_regra_qualidade
ORDER BY status, regra_id;

-- Associação descritiva por UF, produto e primeiro semestre.
WITH vendas AS (
  SELECT ano, uf, produto_analitico, vendedor_chave,
         SUM(volume_liquido_litros) AS volume_litros
  FROM gold_fato_venda_empresa_uf_mes
  WHERE mes <= 6 AND volume_liquido_litros > 0
  GROUP BY ano, uf, produto_analitico, vendedor_chave
), participacao AS (
  SELECT *,
         volume_litros / SUM(volume_litros) OVER (PARTITION BY ano, uf, produto_analitico) AS participacao
  FROM vendas
), concentracao AS (
  SELECT ano, uf, produto_analitico,
         SUM(volume_litros) AS volume_litros,
         SUM(POWER(participacao, 2) * 10000) AS hhi,
         SUM(CASE WHEN posicao <= 3 THEN participacao * 100 ELSE 0 END) AS top3_pct
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (
             PARTITION BY ano, uf, produto_analitico
             ORDER BY volume_litros DESC, vendedor_chave
           ) AS posicao
    FROM participacao
  )
  GROUP BY ano, uf, produto_analitico
), preco AS (
  SELECT ano, uf, produto_analitico,
         PERCENTILE_APPROX(mediana_preco, 0.50, 10000) AS preco_h1
  FROM gold_fato_preco_uf_mes
  WHERE mes <= 6
  GROUP BY ano, uf, produto_analitico
), base AS (
  SELECT c.ano, c.produto_analitico, c.uf,
         LN(c.volume_litros) AS log_volume,
         c.hhi, c.top3_pct, p.preco_h1
  FROM concentracao c
  INNER JOIN preco p
    ON c.ano = p.ano
   AND c.uf = p.uf
   AND c.produto_analitico = p.produto_analitico
)
SELECT ano, produto_analitico,
       COUNT(*) AS ufs_comparaveis,
       ROUND(CORR(log_volume, preco_h1), 4) AS corr_log_volume_preco,
       ROUND(CORR(hhi, preco_h1), 4) AS corr_hhi_preco,
       ROUND(CORR(top3_pct, preco_h1), 4) AS corr_top3_preco
FROM base
GROUP BY ano, produto_analitico
ORDER BY produto_analitico, ano;
