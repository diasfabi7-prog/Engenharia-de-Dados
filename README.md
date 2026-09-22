# MVP de Engenharia de Dados — Mercado de combustíveis no Brasil

Neste projeto, construí um pipeline de dados no Databricks para organizar e analisar bases públicas da Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP). O trabalho acompanha o volume declarado por vendedor, a concentração por UF, os preços de revenda e a participação dos agentes regulados presentes no arquivo do SIMP.

O projeto foi estruturado como um lakehouse, com rastreabilidade desde o arquivo de origem até as tabelas utilizadas nas consultas analíticas.

## Documento de entrega

O relatório completo do MVP está em **[relatorio-mvp-fabiola-dias-carvalho.pdf](relatorio-mvp-fabiola-dias-carvalho.pdf)**. Ele reúne, em um único documento: contexto de negócio e perguntas, coleta e licença dos dados, modelagem e catálogo, pipeline de carga (com evidências de execução no Databricks), qualidade de dados, análise e respostas às perguntas do projeto, limitações e autoavaliação. O Apêndice A do relatório mapeia cada requisito do enunciado à seção correspondente.

## Objetivo

Analisar gasolina C comum e etanol hidratado comum nas Unidades da Federação entre janeiro de 2022 e junho de 2026. O estudo procura responder:

- quais vendedores apresentam os maiores volumes declarados em cada UF;
- como evoluem a participação do líder, o Top 3 e o índice HHI;
- como Vibra, Ipiranga, Raízen e ALE aparecem na fonte logística;
- como volume, concentração e preços se comportam no mesmo recorte de UF, mês e produto;
- quais agentes regulados lideram o volume informado no SIMP;
- em que medida as fontes logística, municipal e SIMP são comparáveis.

As definições, limitações e unidades de análise estão em [docs/objetivo.md](docs/objetivo.md).

## Cobertura dos dados

| Fonte | Granularidade principal | Período utilizado |
|---|---|---|
| Logística 02 | vendedor, UF, produto e mês | jan/2022 a jun/2026 |
| SIMP — combustíveis líquidos | agente, destino, UF, produto e mês | jan/2022 a jun/2026 |
| Pesquisa de preços | posto, produto e data de coleta | jan/2022 a jun/2026 |
| Vendas municipais | município, produto e ano | 2022 a 2024 |
| Cadastro de revendedores | CNPJ e data da extração | fotografia da carga |

O núcleo mensal possui 54 meses. Nas comparações que incluem 2026, são usados os primeiros semestres de todos os anos. A base municipal permanece em 2022–2024 porque esse é o intervalo anual disponível para o cruzamento realizado.

## Arquitetura

```text
Fontes da ANP
      │
      ▼
Coleta e manifesto de arquivos
      │
      ▼
Bronze ── arquivos recebidos e controle de lote
      │
      ▼
Silver ── padronização, tipagem e regras de domínio
      │
      ▼
Gold ── concentração, preços, reconciliação e agentes
      │
      ▼
Consultas analíticas e validações de qualidade
```

Os dados brutos não são versionados. O coletor registra URL, data de acesso, tamanho e hash de cada arquivo para permitir a conferência da origem.

## Resultado da execução validada

A execução final no Databricks foi concluída com os seguintes resultados:

| Indicador | Resultado |
|---|---:|
| Período mensal processado | 54 meses |
| Fontes originais carregadas | 14 arquivos |
| Tabelas gerenciadas | 52 |
| Atributos catalogados | 650 |
| Regras de qualidade | 43 |
| Regras aprovadas | 22 |
| Regras com atenção | 7 |
| Regras informativas | 14 |

As consultas finais incluem ranking de vendedores, participação no volume declarado, concentração por HHI, evolução das empresas selecionadas, preços de revenda, reconciliação anual e participação dos agentes regulados no SIMP. As fontes são analisadas de acordo com a granularidade e o escopo de cada uma; nomes semelhantes entre vendedor, agente e bandeira não são tratados automaticamente como a mesma entidade.

## Principais resultados

Para manter a comparação com 2026, os resultados temporais abaixo usam o primeiro semestre de cada ano.

- O volume declarado de gasolina C passou de 15,941 bilhões de litros em 2022 para 19,215 bilhões em 2026, aumento de 20,5%.
- O etanol hidratado passou de 8,461 para 12,255 bilhões de litros, aumento de 44,8%.
- Na gasolina C, a Vibra liderou 2026 com 21,88% do volume positivo. Ipiranga teve 17,68% e Raízen, 15,61%.
- No etanol, as três primeiras ficaram próximas: Ipiranga com 11,44%, Raízen com 11,40% e Vibra com 11,00%.
- Entre 2022 e 2026, a participação da Vibra na gasolina passou de 24,76% para 21,88%. Ipiranga passou de 18,48% para 17,68%, Raízen de 17,14% para 15,61% e ALE de 3,08% para 3,14%.
- A concentração estadual apresentou diferenças relevantes. No etanol do Amapá, o HHI passou de 8.251 para 4.200; no Rio Grande do Sul, passou de 4.438 para 1.056.
- A mediana das medianas estaduais de preço da gasolina C passou de R$ 7,17 por litro em 2022 para R$ 6,59 em 2026. No etanol, passou de R$ 5,70 para R$ 4,99.
- No SIMP, Vibra, Ipiranga e Raízen responderam por 55,24% da gasolina C em 2026. No etanol, Ipiranga, Raízen e Vibra somaram 42,60%.
- Os postos bandeirados receberam 61,16% do volume de gasolina C informado no SIMP, enquanto os postos de bandeira branca receberam 38,33%. No etanol, a bandeira branca respondeu por 51,62% e os postos bandeirados por 46,31%.

Esses resultados são descritivos. As correlações e participações calculadas não estabelecem causalidade e devem ser interpretadas dentro da cobertura de cada fonte.

## Camadas e principais saídas

| Camada | Conteúdo |
|---|---|
| Bronze | arquivos recebidos, metadados e identificação do lote |
| Silver | fatos padronizados de logística, SIMP, preços, vendas municipais e cadastro |
| Gold | participação, ranking, HHI, preços, reconciliação, cobertura e qualidade |

Entre as tabelas analíticas estão `gold_fato_venda_empresa_uf_mes`, `gold_fato_concentracao_uf_mes`, `gold_fato_preco_uf_mes`, `gold_fato_venda_simp_agente_uf_mes` e `gold_comparacao_simp_logistica_uf_mes`.

## Qualidade e rastreabilidade

As regras verificam completude, domínio, unicidade, consistência e cobertura temporal. Cada ocorrência permanece associada ao lote e à execução que a produziu. A regra `VENDA_MUNICIPIO_004`, responsável pela duplicidade da chave município, produto e ano, considera somente os registros dentro do recorte municipal do estudo.

Os status de atenção e informativo não são descartados. Eles registram limitações ou diferenças que precisam acompanhar a análise, como valores fora do recorte, cobertura amostral de preços e divergências de escopo entre SIMP e Logística 02.

## Fontes

- [Logística 02 da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/movimentacaologistica.zip): volume por vendedor, UF, produto e mês.
- [SIMP — combustíveis líquidos](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/liquidos.zip): agente regulado, mercado destinatário, UF, produto e mês.
- [Série histórica de preços da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis): observações de revenda por posto.
- [Vendas municipais da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/vendas-de-derivados-de-petroleo-e-biocombustiveis): escala anual por município.
- [Cadastro de revendedores da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/dados-cadastrais-dos-revendedores-varejistas-de-combustiveis-automotivos): contexto atual de rede e bandeira.

A origem, a linhagem e as condições de uso estão documentadas em [docs/fontes_e_linhagem.md](docs/fontes_e_linhagem.md) e na Seção 2 do relatório.

## Estrutura do repositório

```text
relatorio-mvp-fabiola-dias-carvalho.pdf   relatório completo da entrega (Etapa 5)
config/      mapeamentos, catálogo de atributos e exemplo de ambiente
data/        estrutura local para dados e metadados não versionados
docs/        objetivo, cobertura, linhagem, modelo, catálogo e execução
notebooks/   preparação, carga, transformação, qualidade e análises
scripts/     coleta e inspeção dos arquivos oficiais
tests/       verificações dos utilitários de coleta e inspeção
```

## Ordem de execução

1. Baixar os arquivos da ANP com `python3 scripts/download_anp.py`.
2. Inspecionar os arquivos com `python3 scripts/inspect_raw.py`.
3. Enviar os arquivos brutos e os CSVs de `config/` para um Volume do Databricks.
4. Ajustar catálogo, schema e caminhos conforme `config/ambiente.example.yml`.
5. Executar os notebooks na ordem abaixo:

```text
00_setup_ambiente.sql
00_preparar_arquivos_anp.py
01_ingestao_bronze.py
02_transformacao_modelo.py
03_qualidade_dados.py
04_analises.sql
```

O roteiro detalhado está em [docs/execucao_databricks.md](docs/execucao_databricks.md). O modelo e o catálogo estão em [docs/modelo_dados.md](docs/modelo_dados.md) e [docs/catalogo_dados.md](docs/catalogo_dados.md).

## Verificações locais

As verificações não baixam os dados da ANP:

```bash
python3 -m pip install -r requirements-dev.txt
make check
```

O comando valida a sintaxe dos arquivos Python, executa o lint, os testes unitários e os testes rápidos dos utilitários.

## Limites de interpretação

- volume declarado por vendedor não equivale automaticamente a participação de marca no varejo;
- agente regulado do SIMP e vendedor da Logística 02 são dimensões diferentes;
- a pesquisa de preços é amostral;
- o cadastro de revendedores representa a situação da data de extração;
- diferenças entre as fontes são tratadas como diferenças de escopo antes de serem classificadas como erro.
