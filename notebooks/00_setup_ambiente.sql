-- Databricks SQL
-- Ajuste o catálogo somente se o workspace de destino usar outro nome.

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS anp_combustiveis_br_2022_2026;
USE SCHEMA anp_combustiveis_br_2022_2026;

CREATE VOLUME IF NOT EXISTS anp;

SHOW VOLUMES;
