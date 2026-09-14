# Catálogo de dados

O catálogo observado é produzido pelo notebook `03_qualidade_dados.py` na tabela `gold_catalogo_atributos`. Para cada atributo de todas as tabelas Silver e Gold, ele registra tipo Spark, quantidade de linhas, nulos, distintos, mínimo, máximo e, para campos categóricos, as categorias mais frequentes observadas no lote executado.

As descrições de negócio, domínios esperados, unidades e linhagem ficam em `config/catalogo_atributos.csv`. A revisão histórica do lote de 11 de setembro incluiu os atributos do SIMP, dos fatos por agente e destino comercial, do mart SIMP e das tabelas de comparação. O catálogo observado do lote histórico de 2022–2024 é mantido apenas como histórico. Em cada reexecução, o notebook 03 recalcula o catálogo com novo `lote_id` e `execucao_id`. Quando uma coluna técnica não tem entrada manual, o notebook completa uma descrição e domínio compatíveis com seu tipo. Mínimos, máximos e categorias vêm sempre da execução real, não de valores preenchidos no dicionário.

## Dicionário das fontes

| Fonte | Campos principais | Tratamento na Silver |
|---|---|---|
| Logística 02 | `Período`, `UF Destino`, `Produto`, `Vendedor`, `Qtd Produto Líquido` | período vira `data_referencia`; quantidade vira decimal; vendedor recebe chave normalizada; UF, volume, produto e duplicidade recebem flags |
| SIMP / combustíveis líquidos | `Ano`, `Mês`, `Agente Regulado`, produto, `UF Destino`, `Mercado Destinatário`, `Quantidade de Produto (mil m³)` | ano e mês viram `data_referencia`; decimal em mil m³ é preservado e convertido para litros; agente, UF, produto e mercado recebem chaves e flags |
| Preços semanais | UF, município, revenda, CNPJ, produto, data, valor de venda, unidade e bandeira | datas e decimais tipados; município conciliado ao IBGE; produto mapeado; chave natural marcada |
| Vendas municipais | ano, grande região, UF, produto, código IBGE, município e vendas | código IBGE vira chave geográfica; volume é decimal; produto é mapeado |
| Cadastro de revendedores | CNPJ, razão social, UF, município, bandeira e datas cadastrais | retrato de extração separado do histórico de preços e volumes |

## Domínios que orientam a qualidade

| Atributo | Domínio esperado | Tratamento se houver exceção |
|---|---|---|
| `data_referencia` | primeiro dia do mês entre 2022-01-01 e 2026-06-01 para o núcleo mensal | linha preservada na Silver e sinalizada em regra de qualidade |
| `ano` em fatos municipais | 2022 a 2024 | a fonte municipal é anual; anos fora desse intervalo são sinalizados e não são usados para estender o mart municipal |
| `uf` na logística | uma das 27 siglas de UF | valores como `N/A` ficam na Silver, mas não entram em agregados estaduais |
| `volume_liquido_litros` | número; negativos podem ser ajustes declarados | flag `ajuste_negativo`; nunca apagado para melhorar o resultado |
| `volume_litros` municipal | número maior ou igual a zero | linha sinalizada quando inválida |
| `preco_venda` | decimal maior que zero | linha fica auditável; só preço válido entra nas agregações |
| `codigo_ibge` | sete dígitos quando conciliado | ausência gera flag, não substituição por nome livre |
| `cnpj` | 14 dígitos quando válido | a formatação é removida e a validade é registrada |
| `produto_analitico` | valor presente no mapeamento ou `NAO_MAPEADO` | o valor de origem é preservado e a cobertura do mapeamento é mensurada |
| `participacao_pct` | 0 a 100 | calculada somente com saldo positivo de vendedor e total positivo de UF |
| `hhi` | 0 a 10.000 | deriva das participações por vendedor |
| `quantidade_mil_m3` do SIMP | decimal maior ou igual a zero | origem e unidade são preservadas; a medida em litros é derivada de forma explícita |
| `agente_regulado` | texto não vazio para fatos de agente | valor publicado permanece disponível; chave normalizada não substitui o original |
| `mercado_destinatario` | domínio publicado pela ANP | categorias não previstas são preservadas e perfiladas |
| `status_comparacao` | `PROXIMO_EM_VOLUME`, `DIVERGENCIA_DE_ESCOPO` ou `SEM_BASE_COMPARAVEL` | descreve a comparação entre fontes e não altera os valores de origem |

## Tabelas principais

| Tabela | Finalidade | Granularidade |
|---|---|---|
| `silver_venda_empresa_uf_mes` | venda logística padronizada com flags | linha recebida da Logística 02 |
| `silver_venda_simp_liquidos` | venda SIMP padronizada com unidade original e medida em litros | agente × mercado × UF × produto × mês |
| `silver_preco_coletado` | preço de revenda padronizado | posto × produto × data |
| `silver_venda_municipio` | venda anual municipal padronizada | município × produto × ano |
| `silver_cadastro_revenda` | fotografia cadastral padronizada | CNPJ × data de extração |
| `gold_fato_venda_empresa_uf_mes` | volume líquido por vendedor | vendedor × UF × produto × mês |
| `gold_fato_participacao_vendedor_uf_mes` | participação e ranking | vendedor × UF × produto × mês |
| `gold_fato_concentracao_uf_mes` | HHI, líder e Top 3 | UF × produto × mês |
| `gold_fato_venda_simp_agente_uf_mes` | volume do painel por agente regulado | agente × UF × produto × mês |
| `gold_fato_venda_simp_mercado_uf_mes` | volume do painel por mercado destinatário | mercado × UF × produto × mês |
| `gold_mart_simp_uf_mes` | contexto de volume SIMP, concentração e preço por UF | UF × produto × mês |
| `gold_comparacao_simp_logistica_uf_mes` | comparação de volumes das duas fontes | UF × produto × mês |
| `gold_fato_preco_uf_mes` | preço e dispersão por UF | UF × produto × mês |
| `gold_mart_mercado_uf_mes` | contexto integrado de volume, concentração e preço | UF × produto × mês |
| `gold_fato_mercado_municipio_anual` | comparação municipal de preço e volume | município × produto × ano |
| `gold_reconciliacao_volume_uf_ano` | comparação das duas fontes de volume | UF × grupo de produto × ano |
| `gold_controle_execucao` | marcos de início e conclusão da transformação | execução × evento |
| `gold_catalogo_atributos` | perfil por atributo e dicionário aplicado | tabela × coluna |
| `gold_resultado_regra_qualidade` | resultado das regras de qualidade | regra × tabela |

## Como usar o catálogo na entrega

1. Execute o notebook de qualidade com `perfil_completo = true`.
2. Registre a contagem, os nulos, o mínimo, o máximo e as categorias observadas para os campos usados nas análises.
3. Verifique `gold_catalogo_atributos` e `gold_resultado_regra_qualidade` ao final de cada execução.
4. Ao discutir uma ressalva, cite a regra, a tabela e a quantidade afetada. Não substitua a ressalva por uma limpeza silenciosa.
