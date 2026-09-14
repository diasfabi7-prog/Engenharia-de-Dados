# MVP de Engenharia de Dados - Mercado de combustíveis no Brasil

Neste projeto, organizei dados públicos da ANP em um lakehouse no Databricks para analisar o volume declarado por vendedor, a concentração por UF, os preços de revenda e a leitura complementar do mercado por agente regulado.

## Objetivo

Descrever a evolução de gasolina C comum e etanol hidratado comum nas UFs brasileiras entre janeiro de 2022 e junho de 2026. A análise combina volume por vendedor, indicadores de concentração, preços de revenda, vendas municipais anuais e dados do SIMP. A camada municipal cobre 2022 a 2024, que é o intervalo disponível para esse cruzamento.

As perguntas de negócio, limites e unidades de análise estão em [docs/objetivo.md](docs/objetivo.md).

## Fontes

- [Logística 02 da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/movimentacaologistica.zip): volume por vendedor, UF, produto e mês.
- [SIMP - combustíveis líquidos](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/arquivos/mdpg/liquidos.zip): agente regulado, mercado destinatário, UF, produto e mês.
- [Série histórica de preços da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis): observações de revenda por posto.
- [Vendas municipais da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/vendas-de-derivados-de-petroleo-e-biocombustiveis): escala anual por município.
- [Cadastro de revendedores da ANP](https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/dados-cadastrais-dos-revendedores-varejistas-de-combustiveis-automotivos): contexto atual de rede e bandeira.

Os dados brutos não são versionados. O coletor registra URL, data de acesso, tamanho e hash dos arquivos baixados.

## Estrutura

```text
config/      mapeamentos e exemplo de ambiente
data/        estrutura local para dados e metadados não versionados
docs/        objetivo, linhagem, modelo, catálogo e execução
notebooks/   setup, preparação, carga, transformação, qualidade e análises
scripts/     coleta e inspeção dos arquivos oficiais
tests/       verificações dos utilitários de coleta e inspeção
```

## Execução

1. Baixe os arquivos da ANP com `python3 scripts/download_anp.py`.
2. Inspecione os arquivos com `python3 scripts/inspect_raw.py`.
3. Copie os arquivos brutos e os CSVs de `config/` para um Volume do Databricks.
4. Ajuste os caminhos em `config/ambiente.example.yml`.
5. Execute no Databricks, nesta ordem: `00_setup_ambiente.sql`, `00_preparar_arquivos_anp.py`, `01_ingestao_bronze.py`, `02_transformacao_modelo.py`, `03_qualidade_dados.py` e `04_analises.sql`.

O roteiro de execução está em [docs/execucao_databricks.md](docs/execucao_databricks.md). O modelo, a linhagem e o catálogo de dados estão em [docs/modelo_dados.md](docs/modelo_dados.md), [docs/fontes_e_linhagem.md](docs/fontes_e_linhagem.md) e [docs/catalogo_dados.md](docs/catalogo_dados.md).

## Verificações locais

Para executar as verificações dos utilitários:

```bash
python3 -m pip install -r requirements-dev.txt
make check
```

Os documentos de resultados, evidências visuais, autoavaliação e apresentação são materiais complementares da entrega na plataforma da PUC.
