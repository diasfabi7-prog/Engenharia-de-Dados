# Fontes e linhagem dos dados

## Fontes utilizadas

| Origem | Arquivo ou endpoint | Campos que sustentam a análise | Granularidade de origem | Papel no modelo |
|---|---|---|---|---|
| ANP — Logística 02 | [movimentacaologistica.zip](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/movimentacaologistica.zip) | `Período`, `UF Destino`, `Produto`, `Vendedor`, `Qtd Produto Líquido` | vendedor × UF destino × produto × mês | volume, participação e concentração |
| ANP — Painel do Mercado Brasileiro de Combustíveis Líquidos (SIMP) | [liquidos.zip](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/liquidos.zip), arquivo `Liquidos_Vendas_Atual.csv` | `Ano`, `Mês`, `Agente Regulado`, produto, `UF Destino`, `Mercado Destinatário`, `Quantidade de Produto (mil m³)` | agente × mercado destinatário × UF destino × produto × mês | ranking de agentes, destino comercial e comparação de escopo |
| ANP — série histórica de preços | [página da série](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis) | produto, data, UF, município, CNPJ, revenda, bandeira, preço de venda | posto × produto × data de coleta | preço e cobertura de pesquisa |
| ANP — vendas de derivados e biocombustíveis | [página de dados abertos](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/vendas-de-derivados-de-petroleo-e-biocombustiveis) | ano, UF, código IBGE, município, produto, vendas | município × produto × ano | escala municipal e reconciliação anual |
| ANP — cadastro de revendedores | [página de dados cadastrais](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/dados-cadastrais-dos-revendedores-varejistas-de-combustiveis-automotivos) | CNPJ, razão social, UF, município, bandeira, datas cadastrais | revendedor × fotografia de extração | contexto da rede varejista |
| Projeto | `config/produto_mapeamento.csv` | fonte, produto de origem, produto analítico, grupo de reconciliação | produto publicado | padronização explícita |
| Projeto | `config/empresa_grupo_mapeamento.csv` | vendedor normalizado, empresa canônica, grupo econômico | vendedor publicado | leitura dos grupos selecionados |

O metadado oficial da base logística está disponível em [Metadado unificado — Logística](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/metadado-unificado-logistica.pdf). O script de coleta registra a URL efetivamente utilizada, horário de acesso, arquivo local, tamanho e hash SHA-256. A inspeção posterior registra codificação, delimitador, colunas, período observado e número de linhas em `data/metadata/`.

## Cobertura temporal adotada

O projeto adota janeiro de 2022 a junho de 2026 como núcleo mensal das fontes Logística 02, SIMP e preços. As vendas municipais permanecem em 2022–2024 porque a fonte tem granularidade anual e o arquivo disponível termina nesse ano. A tabela completa de cobertura e a regra de comparar somente primeiros semestres quando 2026 participa estão em [cobertura_fontes.md](cobertura_fontes.md).

Essa é uma decisão de modelagem e de filtro. Cada execução deve registrar o lote, o período aplicado e o schema de destino, para que a origem dos resultados analíticos permaneça rastreável.

## Papel e cautelas de cada fonte

### Logística 02 — núcleo do projeto

Essa fonte fornece o volume líquido informado por vendedor para uma UF de destino, produto e período. Ela sustenta o indicador de participação e as medidas de concentração. A carga preserva o nome publicado do vendedor e cria uma chave normalizada apenas para mapeamentos controlados de grupos econômicos.

O volume é tratado como dado declaratório da fonte. Registros com quantidade negativa, caso existentes, são marcados como ajuste e permanecem auditáveis; o projeto não os elimina para melhorar artificialmente os totais. UFs não informadas ou fora do domínio esperado também permanecem na camada Silver e são excluídas somente dos agregados estaduais.

### SIMP — base que alimenta o painel oficial de combustíveis líquidos

O arquivo `Liquidos_Vendas_Atual.csv`, distribuído dentro de `liquidos.zip`, é a fonte selecionada do conjunto usado no painel da ANP. Ele acrescenta duas dimensões que não existem na mesma forma na Logística 02: `Agente Regulado` e `Mercado Destinatário`. A quantidade vem em mil m³ e é convertida para litros por `mil m³ × 1.000.000`; o campo original e a unidade continuam disponíveis na camada Silver.

O arquivo usa codificação ISO-8859-1 e separador `;`. A UF `NI`, quando presente, é preservada na Silver para auditoria e não entra em agregado estadual. Para os produtos de interesse, o mapeamento versionado cobre gasolina C comum e etanol hidratado comum.

SIMP e Logística 02 seguem trilhas paralelas. Uma correspondência de nomes normalizados entre `Agente Regulado` e `Vendedor` é apenas um recurso de diagnóstico: não prova identidade jurídica nem transforma uma fonte na outra. Por isso, a tabela comparativa mantém o volume de ambas as fontes, a diferença e um status de escopo; ela não produz fator de correção.

### Preços de revenda — contexto agregado

A série de preços representa visitas de pesquisa a postos. Ela permite observar nível e dispersão de preços, bem como cobertura de município, semana e UF. Como não traz o mesmo agente econômico da Logística 02, o cruzamento é feito apenas depois da agregação por `UF + mês + produto_analitico`.

`Bandeira` e CNPJ de revenda permanecem disponíveis para análises varejistas próprias. Não são utilizados para deduzir que uma bandeira corresponde ao vendedor da base logística.

### Vendas municipais — comparação anual de escopo

As vendas municipais têm granularidade anual e código IBGE. Servem para avaliar escala municipal e para confrontar, por UF e ano, totais obtidos por duas fontes distintas. A reconciliação é documentada por produto e cobertura de meses; diferença não é corrigida por uma regra implícita.

Para gasolina C, o grupo de reconciliação pode incorporar as variantes de gasolina presentes na fonte logística quando a definição publicada exigir isso. Para etanol, qualquer diferença observada permanece destacada como limite de comparabilidade até que a documentação das fontes justifique outra decisão.

### Cadastro de revendedores — fotografia atual

O cadastro é usado para descrever a rede no momento da extração e apoiar auditorias de CNPJ, UF e bandeira. Não é usado como evidência de que um posto operava, tinha determinada bandeira ou atendia a um vendedor em qualquer mês do núcleo 2022–junho de 2026.

## Fluxo de linhagem

```text
ANP: Logística 02 ───────────┐
ANP: SIMP / líquidos ─────────┤
ANP: preços semanais ─────────┼──> Volume / raw ──> Bronze (arquivo, hash, lote)
ANP: vendas municipais ───────┤                              |
ANP: cadastro de revendedores ┘                              v
configurações versionadas ─────────────────────────> Silver (tipos, chaves e flags)
                                                               |
                                     ┌─────────────────────────┴────────────────────────┐
                                     v                                                  v
                          dimensões conformadas                         fatos Logística, SIMP e preço
                                     \                                                  /
                                      \                                                /
                                       └──> Gold: mercado, comparação de fontes, qualidade
```

## Transformações rastreáveis

| Transformação | Regra | Motivo | Evidência |
|---|---|---|---|
| Identificação do arquivo | URL, hash, data de acesso e lote | reproduzir a origem exata | manifesto e `bronze_lote_carga` |
| Cabeçalhos e codificação | normalização técnica sem alterar valor de negócio | permitir leitura consistente | Bronze e manifesto de inspeção |
| Período logístico | conversão para mês de referência | conformar a dimensão de tempo | `silver_venda_empresa_uf_mes` |
| Quantidade líquida | conversão decimal e flag de ajuste negativo | preservar medidas e exceções | `volume_liquido_litros`, `ajuste_negativo` |
| Período SIMP | `Ano` e `Mês` convertidos para `data_referencia` | conformar a dimensão de tempo sem perder o recorte mensal | `silver_venda_simp_liquidos` |
| Quantidade SIMP | `Quantidade de Produto (mil m³) × 1.000.000` | expor a medida em litros com a unidade de origem registrada | `volume_simp_litros` |
| Agente e destino comercial | nome de origem preservado; chave normalizada e dimensão de mercado | permitir ranking e análise de destino sem equivalência implícita com vendedor | `gold_dim_agente_simp`, `gold_dim_mercado_destino` |
| UF e produto | normalização controlada por tabelas de referência | assegurar chaves comparáveis | `gold_dim_uf`, `gold_dim_produto` |
| Vendedor | nome de origem preservado; chave normalizada para mapeamento opcional | evitar agrupamentos escondidos | `gold_dim_empresa_vendedora` |
| Preço | conversão de data e decimal; agregação de observações | formar medidas por UF/mês/produto | fatos de preço |
| Município | código IBGE nas vendas e nome normalizado na pesquisa | manter a chave geográfica mais confiável | `gold_dim_municipio` |
| Participação | saldo positivo do vendedor dividido pelo total positivo da mesma UF/mês/produto | cálculo reproduzível de concentração sem ocultar ajustes negativos | fatos de participação e concentração |
| Reconciliação | comparação anual por UF e grupo de produto | explicitar compatibilidade e diferença | `gold_reconciliacao_volume_uf_ano` |

## Chaves de integração

| Integração | Chave | Regra |
|---|---|---|
| Volume e participação | `data_referencia + uf + produto_analitico + vendedor` | permanece no nível mensal da fonte logística |
| Volume e preço | `data_referencia + uf + produto_analitico` | cada lado é agregado antes da junção |
| Logística e vendas municipais | `ano + uf + grupo_reconciliacao_municipal` | comparativo anual com cobertura de meses |
| SIMP e preço | `data_referencia + uf + produto_analitico` | cada lado é agregado antes da associação descritiva |
| SIMP e Logística 02 | `data_referencia + uf + produto_analitico` | comparação de fontes; valores permanecem separados |
| Preço e vendas municipais | `ano + codigo_ibge + produto_analitico` | utilizado no mart municipal, separado do mart mensal |
| Cadastro e preço | CNPJ somente para auditoria de fotografia | não infere histórico cadastral |

## Limites de linhagem que o projeto preserva

- A origem do volume é sempre identificável por arquivo e lote, inclusive após reprocessamento.
- O mapeamento de Vibra, Ipiranga, Raízen e ALE é explícito e não substitui o nome original do vendedor.
- Registros não mapeados não são descartados: aparecem como não classificados quando o agrupamento econômico não é conhecido.
- A dimensão de bandeira não alimenta participação de vendedor e não constitui uma ponte entre venda logística e posto pesquisado.
- `Agente Regulado` do SIMP não é promovido a `Vendedor` da Logística 02 por semelhança de texto. A normalização só documenta a cobertura do diagnóstico.
- A diferença entre SIMP e Logística 02 é exibida com a classificação de escopo. Gasolina C pode apresentar totais próximos enquanto etanol hidratado não; o resultado não é homogeneizado.
- Toda tabela Gold aponta para o lote usado na sua construção. A análise final deve informar esse lote e a data de acesso às fontes.
