# Execução no Databricks

## Preparação

1. Crie um Volume para receber `raw`, `config` e `metadata`.
2. Copie para o Volume os arquivos baixados pela coleta e os CSVs de `config/`.
3. Ajuste catálogo, schema e caminhos conforme `config/ambiente.example.yml`.

## Ordem dos notebooks

1. `00_setup_ambiente.sql`: cria o schema, as tabelas de controle e os parâmetros iniciais.
2. `00_preparar_arquivos_anp.py`: identifica e extrai os arquivos recebidos no Volume.
3. `01_ingestao_bronze.py`: lê os arquivos de origem e registra o lote Bronze.
4. `02_transformacao_modelo.py`: padroniza os dados e publica as camadas Silver e Gold.
5. `03_qualidade_dados.py`: perfila atributos e executa as regras de qualidade.
6. `04_analises.sql`: responde às perguntas de negócio com as tabelas Gold.

## Pontos de conferência

- Verifique o status da execução e o lote selecionado antes de consultar as tabelas Gold.
- Confirme o período mensal de janeiro de 2022 a junho de 2026 e a camada municipal de 2022 a 2024.
- Revise as tabelas de catálogo e qualidade após a transformação.
- Nas análises, informe período, UF, produto, unidade de medida e limite de interpretação de cada resultado.

## Modelo de execução

O pipeline usa arquivos públicos da ANP, armazenamento em Volume, carga Bronze, padronização Silver e tabelas Gold para qualidade e análises. Os arquivos brutos e os manifestos de execução permanecem no ambiente de dados e não são versionados no GitHub.
