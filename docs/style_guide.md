# Style Guide — retail_medallion

Conventions every model, test and macro in this project follows.

## Naming conventions

- **Staging models:** `stg_<source>`, e.g. `stg_customers`. One per raw
  source, named after it.
- **Intermediate models:** `int_<business_concept>`, e.g.
  `int_order_lines`. Named for what they represent, not the sources used.
- **Marts:** `dim_<entity>` for dimensions, `fct_<process>` for facts, e.g.
  `dim_customers`, `fct_orders`.
- **Snapshots:** `<entity>_snapshot`, e.g. `customers_snapshot`.
- **Macros:** `snake_case` verb phrases, e.g. `cents_to_dollars`,
  `safe_divide`.
- **Singular tests:** `assert_<rule>`, e.g.
  `assert_order_revenue_non_negative`. The name states the invariant; the
  query returns the violating rows.
- **Columns:** `snake_case`, full words (`unit_price_dollars`, not
  `unit_prc_dlrs`). Surrogate keys end in `_id`; dollar amounts end in
  `_dollars`; cent amounts end in `_cents`.
- **CTEs:** `source`, then `renamed`, then business-named CTEs
  (`orders`, `products`, `order_stats`). Final `select` reads from the last
  CTE only.

## Layering rules

- `staging` may reference **only** seeds (`ref('raw_*')`) — never another
  staging model, never anything upstream.
- `intermediate` may reference **only** staging models.
- `marts` may reference **only** intermediate models, staging models, or
  other marts (facts may join dimensions' upstream inputs, not dims
  themselves, to avoid fan-out surprises — here facts build on
  `int_order_lines`).
- `snapshots` may reference staging models only.
- Nothing references a seed except staging. Nothing references a snapshot.
- No model reaches across layers (e.g. a mart may not `ref()` a seed).

## Testing requirements

- Every primary key: `unique` + `not_null`.
- Every foreign key: `not_null` + `relationships` to its dimension.
- Every coded column (status, category, type): `accepted_values`.
- Every new business measure gets a singular test asserting its invariant
  (e.g. revenue is never negative).
- Tests live with the model: generic tests in the layer's `schema.yml`,
  singular tests in `tests/`.
- `dbt build` must be green before a change is considered done.

## Documentation standards

- Every model has a `description` (in `config()` or `schema.yml`) stating
  its **layer and grain** in the first sentence.
- Every column in `marts` has a description; staging columns that are
  renamed, cast or derived get one too.
- Every macro has a Jinja doc comment (`{#-- ... --#}`) with purpose,
  args and a usage example.
- Every exposure names its owner and the models it depends on.
- Non-obvious choices (grain quirks, snapshot strategy, backfilled
  columns) are explained in a comment at the decision point, not just in
  the README.

## SQL style

- CTEs over subqueries; one logical step per CTE.
- Keywords lowercase (`select`, `from`, `where`, `join`); identifiers as
  written in the source.
- Table aliases: short but readable (`o` for orders is fine inside a
  3-CTE model; prefer full words in long queries).
- Trailing commas in select lists; each selected column on its own line.
- Joins use explicit `inner join` / `left join` with the `on` clause on
  its own indented line.
- Business logic lives in exactly one place: `int_order_lines` owns
  `line_revenue`; downstream models reuse the column, never recompute it.
- Jinja: `{{ ref('...') }}` and `{{ config(...) }}` only — no
  `{{ source(...) }}` (seeds are the sources here).
