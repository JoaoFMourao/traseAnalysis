# Outline — PPT para a Trase: atribuição do desmatamento a soja e pasto

> **Status:** rascunho para validação (Etapa 1). Depois de aprovado este conteúdo,
> a Etapa 2 (script `presentation/build_pptx.R`, ainda não escrito) vai gerar o
> `.pptx` de verdade a partir deste outline, usando um template visual da MMA.
>
> **Formato de cada slide abaixo:** título, layout genérico (título / conteúdo-texto /
> conteúdo-imagem / duas-imagens / tabela), conteúdo, imagem(ns)/tabela quando houver.
> Os campos de layout são genéricos de propósito — na Etapa 2 eles serão mapeados para
> os nomes reais de layout do template da MMA.
>
> **Fonte dos dados:** Trase SEI-PCS Brazil (beef v2.2, soy v2.6), calculado por
> `R/deforestation_attribution.R`. Todos os números abaixo vêm de
> `OUTPUT_DIR/tables/serie_completa_2013_2023.csv`, filtrado a
> `pasture_year %in% c(2013, 2018, 2023)`.

---

## Slide 1 — Capa

**Layout:** título

**Conteúdo:**
- Título: "Atribuição do desmatamento territorial a soja e pasto — nota técnica para a Trase"
- Subtítulo: "Pré-leitura para a reunião Trase × DPCD/MMA sobre PRODES e commodities"
- DPCD/CGIE — Ministério do Meio Ambiente
- Data: [preencher na Etapa 2, data de envio]

---

## Slide 2 — Contexto e pergunta de pesquisa

**Layout:** conteúdo-texto

**Conteúdo:**
- Contexto: em breve a Trase vai apresentar ao DPCD/MMA a relação entre o PRODES e
  commodities. Numa conversa preliminar, ficou levantada a preocupação de que a
  categoria "não-associado" (desmatamento que não é soja nem pasto) aparece muito
  grande.
- Pergunta de pesquisa (destacar visualmente, ex. caixa/negrito):
  > "Qual % do desmatamento territorial, por bioma e para o Brasil, é atribuível a
  > soja e a pasto — aplicando estritamente a metodologia de janelas de 5 anos
  > definida pela própria Trase — e o que resta como resíduo ('outros')?"
- Escopo: 6 biomas (Amazônia, Cerrado, Mata Atlântica, Caatinga, Pampa, Pantanal) +
  Brasil; 3 janelas de 5 anos não sobrepostas: 2009-2013, 2014-2018, 2019-2023.

---

## Slide 3 — Fontes de dados exatas

**Layout:** tabela

**Conteúdo:**
- Fonte: Trase SEI-PCS Brazil, **beef v2.2** / **soy v2.6**.
- Granularidade: por bioma (`region_trase_id`), 6 biomas.

**Tabela (3 linhas):**

| Arquivo | Cobertura | Coluna de valor |
|---|---|---|
| `territorial_deforestation_biome.csv` | 2008–2024, anual | `deforestation_hectares` |
| `pasture_deforestation_5_year_total_biome.csv` | 2010–2023 | `pasture_deforestation_hectares` |
| `soy_deforestation_5_year_total_biome.csv` | 2014–2024 | `soy_deforestation_hectares` |

---

## Slide 4 — Método: definição oficial e pareamento

**Layout:** conteúdo-texto

**Conteúdo:**
- Citação (genérica por ora — substituir por referência exata se disponível):
  > "conforme documentação SEI-PCS Brazil beef v2.2 / soy v2.6"
- `pasture_deforestation(X)` = pasto mapeado em X sobre desmatamento territorial na
  janela **[X-4, X]** (5 anos, **inclui** X).
- `soy_deforestation(X)` = soja mapeada em X sobre desmatamento territorial na janela
  **[X-5, X-1]** (5 anos, defasagem de 1 ano, **não inclui** X).
- Pareamento: para casar as duas commodities sobre a **mesma janela** de
  desmatamento, casa-se `pasture(X)` com `soy(X+1)` — ambos cobrem `[X-4, X]`.
- Por que só 3 janelas não sobrepostas: os "5 year totals" são janelas móveis — anos
  vizinhos compartilham até 4 dos 5 anos de desmatamento territorial, então não podem
  ser somados/encadeados sem dupla contagem. A série completa ano a ano fica fora do
  escopo deste documento.

---

## Slide 5 — Fórmulas exatas aplicadas

**Layout:** conteúdo-texto (fonte monoespaçada)

**Conteúdo:**
```
pct_soy         = soy_deforestation_ha(X+1) / desmatamento_territorial_total_ha[X-4,X]
pct_pasture     = pasture_deforestation_ha(X) / desmatamento_territorial_total_ha[X-4,X]
pct_outros      = 1 - pct_soy - pct_pasture          (sem clamp; pode ser negativo)
overlap_warning = (pct_soy + pct_pasture) > 1
```
- Para o Brasil: somam-se primeiro os hectares (desmatamento territorial, soja e
  pasto) dos 6 biomas, e só então recalculam-se os 3 percentuais a partir dos totais
  somados — os percentuais de bioma nunca são somados/promediados diretamente.

---

## Slide 6 — Resultados: Brasil agregado

**Layout:** duas-imagens

**Imagens:**
- `figures/brazil_aggregate/brasil_pct_3_periodos.png`
- `figures/brazil_aggregate/brasil_hectares_3_periodos.png`

**Dados de referência (Brasil, 3 períodos):**

| Janela | Desmat. territorial (ha) | Soja (ha) | % Soja | Pasto (ha) | % Pasto | % Outros |
|---|---|---|---|---|---|---|
| 2009-2013 | 10.094.073,64 | 516.868,26 | 5,12% | 4.243.655,59 | 42,04% | 52,84% |
| 2014-2018 | 11.191.061,17 | 808.367,98 | 7,22% | 5.252.942,28 | 46,94% | 45,84% |
| 2019-2023 | 14.211.090,97 | 844.456,26 | 5,94% | 7.372.136,00 | 51,88% | 42,18% |

---

## Slide 7 — Resultados: por bioma, 3 períodos

**Layout:** conteúdo-imagem (imagem larga)

**Imagem:**
- `figures/facet_comparison/comparacao_3_periodos.png`

---

## Slide 8 — Leitura dos resultados

**Layout:** conteúdo-texto

**Conteúdo:**
- No Brasil, soja + pasto explicam uma fatia crescente do desmatamento territorial:
  47,16% → 54,16% → 57,82% (2009-13 → 2014-18 → 2019-23). Ou seja, "outros" caiu de
  52,84% para 42,18% — mas mesmo no período mais recente quase metade do
  desmatamento territorial segue sem associação a soja ou pasto.
- O desmatamento territorial total também cresceu ~40,8% entre o primeiro e o
  último período (10,09 → 14,21 milhões de ha).
- Por bioma, em 2019-2023: Amazônia (78,18%) e Pantanal (76,65%) são os mais
  dominados por pasto; Pampa é o único bioma onde soja (40,10%) supera o pasto
  (0,34%); Mata Atlântica tem o maior resíduo "outros" (74,70%), seguida de perto
  por Cerrado (59,80%) e Pampa (59,56%).
- Nenhum dos 21 casos analisados (3 períodos × 6 biomas × Brasil) disparou
  `overlap_warning` (isto é, nenhum teve `pct_soy + pct_pasture > 1`).

---

## Slide 9 — Tabela-resumo (Brasil, 3 períodos)

**Layout:** tabela

**Tabela (3 linhas — mesmos dados do Slide 6, para referência rápida em formato de
tabela):**

| Janela | Desmat. territorial (ha) | Soja (ha) | % Soja | Pasto (ha) | % Pasto | % Outros |
|---|---|---|---|---|---|---|
| 2009-2013 | 10.094.073,64 | 516.868,26 | 5,12% | 4.243.655,59 | 42,04% | 52,84% |
| 2014-2018 | 11.191.061,17 | 808.367,98 | 7,22% | 5.252.942,28 | 46,94% | 45,84% |
| 2019-2023 | 14.211.090,97 | 844.456,26 | 5,94% | 7.372.136,00 | 51,88% | 42,18% |

---

## Slide 10 — Limitações, notas técnicas e perguntas para a Trase

**Layout:** conteúdo-texto

**Notas técnicas:**
- `pct_outros` não tem clamp e pode ficar negativo se houver sobreposição espacial
  entre soja e pasto recém-convertido (sinalizado via `overlap_warning`) — não
  ocorreu em nenhum dos 3 períodos destacados.
- Assimetria a declarar: nos gráficos em hectares, o componente "outros" é truncado
  em zero (`pmax(total - soja - pasto, 0)`); já `pct_outros` nas tabelas e no
  gráfico percentual não tem essa correção. Não afeta os números aqui apresentados
  (sem overlap), mas é uma escolha de implementação a deixar transparente.
- A cobertura temporal desigual dos 3 CSVs de origem (territorial 2008–2024;
  pasture 2010–2023; soy 2014–2024) limita o intervalo de janelas possíveis.

**Perguntas para a Trase:**
1. Nosso entendimento do pareamento `pasture(X) + soy(X+1)` e da escolha de janelas
   não sobrepostas para comparar períodos está correto?
2. Como a Trase recomenda decompor/explicar a categoria "outros" ao DPCD — existe
   uma quebra adicional (outras culturas, silvicultura, mineração, expansão urbana)
   que reduza esse resíduo?
3. Existe orientação oficial da Trase sobre a sobreposição espacial potencial entre
   soja e pasto (`pct_soy + pct_pasture > 1`)?
4. Há previsão de estender a cobertura temporal dos indicadores de pasture/soy para
   anos mais recentes?
