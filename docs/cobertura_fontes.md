# Cobertura temporal das fontes

O projeto não aplica um único período a todas as fontes. Cada análise respeita a data final efetivamente publicada pela ANP e a granularidade de origem.

| Fonte | Granularidade | Cobertura usada | Papel na entrega |
|---|---|---|---|
| Logística 02 | vendedor × UF × produto × mês | janeiro de 2022 a junho de 2026 | volume, ranking e concentração |
| SIMP - líquidos | agente × destino × UF × produto × mês | janeiro de 2022 a junho de 2026 | leitura por agente, destino e comparação de escopo |
| Pesquisa de preços | posto × produto × data de coleta | janeiro de 2022 a junho de 2026 | preço, dispersão e cobertura de coleta |
| Vendas municipais | município × produto × ano | 2022 a 2024 | escala municipal e reconciliação anual |
| Cadastro de revendedores | CNPJ × data de extração | fotografia da carga | contexto cadastral, sem inferência histórica |

## Recortes usados nas análises

- O núcleo mensal usa 54 meses: janeiro de 2022 a junho de 2026.
- Comparações de evolução usam sempre o primeiro semestre de cada ano. Assim, 2026 não é comparado como se fosse um ano completo.
- O cruzamento municipal permanece em 2022-2024. A ANP divulga essa série por ano e o arquivo disponível ainda termina em 2024.
- O SIMP tem histórico anterior, mas a comparação com Logística 02 começa em 2022, que é o início comum das duas fontes no projeto.

Essa separação é intencional: ausência de dado municipal em 2025-2026 não significa ausência de venda. Ela apenas impede uma análise municipal equivalente nesses anos.
