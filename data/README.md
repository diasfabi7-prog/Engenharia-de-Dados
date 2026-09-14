# Dados locais

Esta pasta recebe os arquivos brutos baixados da ANP, o manifesto da coleta e resultados locais opcionais. Eles não são versionados.

```text
data/
├── raw/        # ZIPs e CSVs de preços, vendas municipais, Logística 02 e cadastro
├── metadata/   # manifestos de download e inspeção
└── processed/  # saídas locais opcionais
```

Os notebooks leem uma cópia dessas pastas enviada para um Volume do Databricks.

Para o recorte mensal configurado, `raw/precos/` deve conter os ZIPs semestrais de 2022 a 2025 e o ZIP do primeiro semestre de 2026. As vendas municipais continuam anuais e são mantidas apenas até 2024. A presença local dos arquivos não substitui a conferência da cobertura depois da carga no Databricks.
