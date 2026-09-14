# Objetivo e questões do projeto

Este documento orienta o recorte, o modelo e as consultas da entrega. Ele foi mantido como referência durante a ampliação do projeto para o recorte nacional, sem apagar as perguntas que justificam as análises.

## Objetivo geral

Construir um pipeline em nuvem que integre dados públicos da ANP para descrever, de janeiro de 2022 a junho de 2026, o volume de gasolina C e etanol hidratado declarado por vendedor em cada UF brasileira, a concentração associada a esse volume, o contexto de preços e a leitura complementar por agente regulado e mercado de destino da base SIMP usada no painel oficial de combustíveis líquidos. A camada de vendas municipais é mantida no período anual disponível, de 2022 a 2024.

O resultado deve ser reprodutível, rastreável desde o arquivo bruto até a tabela analítica e acompanhado de evidências de qualidade por atributo.

## Pergunta central

Como evoluiu o volume de gasolina C e etanol hidratado declarado por vendedor nas Unidades da Federação entre janeiro de 2022 e junho de 2026, qual é a estrutura de concentração observada nesses mercados e o que a fonte SIMP do painel oficial acrescenta, de forma descritiva, sobre agentes, destinos comerciais e preços? No intervalo municipal publicado de 2022 a 2024, como essa leitura se relaciona à escala anual de vendas?

## Perguntas de análise

1. Quais vendedores concentram os maiores volumes declarados em cada UF, mês e produto?
2. Como evoluem a participação do vendedor líder, a participação dos três maiores e o índice HHI por UF, mês e produto?
3. Como se comportam, em termos de volume declarado, as linhas publicadas para Vibra, Ipiranga, Raízen e ALE nos estados onde aparecem, sem somar variantes societárias que não tenham mapeamento explícito?
4. Quais UFs apresentam preços medianos de revenda mais altos, maior dispersão e maior ou menor cobertura de coleta para os produtos analisados?
5. Como concentração de vendedores, preço de revenda e escala do volume variam conjuntamente quando comparados na mesma UF, mês e produto?
6. Em que medida os totais anuais da fonte logística e das vendas municipais são conciliáveis por UF e produto entre 2022 e 2024? Onde a diferença parece decorrer de escopo, cobertura ou definição de produto?
7. O que o cadastro atual de revendedores e bandeiras pode acrescentar como contexto, sem ser usado para reconstituir a rede histórica?
8. Quais agentes regulados lideram o volume nacional no arquivo que alimenta o painel de combustíveis líquidos, como esse volume se distribui entre mercado bandeirado e bandeira branca e como essa fonte se compara à Logística 02 no nível agregado?

## Unidades de análise

| Tema | Unidade | Fonte principal | Medidas |
|---|---|---|---|
| Volume por vendedor | vendedor × UF × produto × mês | Logística 02 | volume líquido em litros |
| Participação e concentração | vendedor/UF × produto × mês | Logística 02 | participação, ranking, Top 3 e HHI |
| Preço de revenda | UF × produto × mês | série semanal de preços | mediana, média, percentis, dispersão e cobertura |
| Escala municipal | município × produto × ano | vendas municipais | volume anual em litros |
| Reconciliação de volume | UF × produto × ano | Logística 02 + vendas municipais | diferença absoluta e percentual |
| Mercado e agentes do painel | agente × mercado destinatário × UF × produto × mês | SIMP / `Liquidos_Vendas_Atual.csv` | volume em litros, participação e posição |
| Comparação de fontes | UF × produto × mês | SIMP + Logística 02 | volume de cada fonte, diferença e status de escopo |
| Contexto de rede | UF × bandeira, fotografia de extração | cadastro de revendedores | quantidade de registros e bandeira declarada |

## Recorte e definições

- **Território:** Brasil, com análise por Unidade da Federação. Registros sem UF de destino válida são preservados para qualidade, mas não integram rankings estaduais.
- **Núcleo mensal:** janeiro de 2022 a junho de 2026 para Logística 02, SIMP e preços. A carga mede os meses efetivamente disponíveis e só publica comparações temporais com cobertura explícita.
- **Comparação temporal:** quando 2026 participa da comparação, o recorte é janeiro a junho de todos os anos. Não se comparam seis meses de 2026 com um ano completo.
- **Escala e reconciliação municipal:** 2022 a 2024, pois a série municipal de origem é anual e o arquivo disponível termina em 2024.
- **Produtos principais:** gasolina C comum e etanol hidratado comum. O mapeamento de produtos é versionado em `config/produto_mapeamento.csv`.
- **Volume:** `Qtd Produto Líquido` publicado na Logística 02, mantido como volume líquido em litros. Ajustes negativos eventualmente presentes na origem são sinalizados; não são apagados sem justificativa.
- **Volume SIMP:** `Quantidade de Produto (mil m³)` do arquivo `Liquidos_Vendas_Atual.csv`, convertida para litros por `mil m³ × 1.000.000`. O valor de origem e a unidade ficam preservados na Silver.
- **Vendedor:** razão social publicada na fonte logística. É um declarante do volume e não deve ser confundido automaticamente com uma distribuidora varejista, uma marca ou uma bandeira.
- **Agente regulado:** valor publicado no SIMP. Ele é tratado como dimensão própria e não recebe equivalência automática com o `Vendedor` da Logística 02; a normalização de nome serve apenas para avaliar cobertura de comparação.
- **Bandeira:** classificação da revenda varejista presente na pesquisa de preços e no cadastro. É tratada em dimensão separada.

## Regras de comparação

O cruzamento principal usa `UF + mês + produto_analitico` depois de cada fonte ser agregada na sua granularidade correta:

1. a Logística 02 gera volume, participação e concentração por vendedor/UF/mês/produto;
2. a pesquisa de preços é resumida para UF/mês/produto, preservando número de coletas, postos e semanas;
3. as duas tabelas são associadas sem atribuir um preço de posto a um vendedor específico;
4. as vendas municipais entram no nível anual, exclusivamente entre 2022 e 2024, para reconciliação e escala; elas não são denominador da participação mensal do vendedor nem completam 2025 ou 2026.
5. o SIMP gera fatos próprios por agente e mercado destinatário; sua comparação com a Logística 02 fica restrita a UF/mês/produto e é identificada como comparação de fontes e escopo.

O indicador de participação é chamado de **participação no volume declarado por vendedor**. Essa formulação é deliberada: a base pode conter diferentes perfis de vendedores e não fornece uma chave que permita inferir participação de marca no varejo.

## Hipóteses de trabalho

- Estados com maior escala de volume podem apresentar estruturas de concentração diferentes, mas a análise não atribui causalidade.
- A concentração observada pode variar por produto e por UF; por isso, o ranking nacional isolado não é suficiente para responder às perguntas do projeto.
- Preço de revenda é resultado de pesquisa amostral. A cobertura deve acompanhar qualquer comparação de preço entre UFs.
- Diferenças entre o total logístico e o total municipal podem apontar divergência de escopo ou classificação; elas são medidas e discutidas, não ajustadas artificialmente.
- Diferenças entre SIMP e Logística 02 podem ser pequenas para um produto e relevantes para outro. Esse contraste é registrado como achado de comparabilidade, não como erro automaticamente corrigível.

## Limitações assumidas

- A fonte logística apresenta volume declarado por vendedor, não uma identificação de cada posto que recebeu ou vendeu o combustível.
- Não existe chave pública direta entre `Vendedor` da Logística 02 e `Bandeira` ou CNPJ do posto da pesquisa de preços.
- `Agente Regulado` do SIMP e `Vendedor` da Logística 02 podem representar nomes próximos, mas não são assumidos como a mesma entidade jurídica apenas pela semelhança textual.
- A pesquisa de preços é amostral; ausência de observação não significa ausência de mercado ou de posto.
- As vendas municipais são anuais, enquanto o núcleo do projeto é mensal. Elas não são usadas para criar uma comparação mensal inexistente.
- O cadastro de revendedores é uma fotografia da data de extração, e não uma série histórica de janeiro de 2022 a junho de 2026.
- Correlação, ranking e concentração descrevem padrões dos dados disponíveis. Não demonstram causa e efeito.
