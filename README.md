# retail_medallion

A dbt project that models **synthetic retail data** in a **medallion
architecture** — bronze → silver → gold — and runs locally on DuckDB with
zero infrastructure. All data is invented (see `seeds/`); there are no real
customers, no real credentials, and nothing is pushed anywhere.

## What it is

A portfolio-quality example of how to structure an analytics engineering
project:

- **Seeds** stand in for raw source extracts (`raw_customers`,
  `raw_orders`, `raw_products`).
- **Staging (bronze)** cleans and lightly types the raw data.
- **Intermediate (silver)** conforms and joins it, computing the core
  business measure (`line_revenue`).
- **Marts (gold)** expose analytics-ready dimensions and facts.
- A **snapshot** keeps SCD Type 2 history of customer attributes.
- **Tests** (generic + singular) guard keys, relationships and business
  rules at every layer.

## Medallion architecture

```
                        ┌─────────────────────┐
                        │  seeds (raw_*.csv)  │  source extracts
                        └──────────┬──────────┘
                                   │ dbt seed
                                   ▼
   ┌──────────────────────────────────────────────────────┐
   │ BRONZE — models/staging        (views)               │
   │ stg_customers · stg_orders · stg_products            │
   │ light cleaning: renames, casts, cents → dollars     │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │ SILVER — models/intermediate   (views)               │
   │ int_order_lines                                      │
   │ conformed join of orders × products;                │
   │ line_revenue = quantity × unit_price_dollars        │
   └──────────────────────────┬───────────────────────────┘
                              ▼
   ┌──────────────────────────────────────────────────────┐
   │ GOLD — models/marts            (tables)              │
   │ dim_customers · dim_products · fct_orders            │
   │ analytics-ready star schema                         │
   └──────────────────────────────────────────────────────┘

   snapshots/customers_snapshot ──► SCD2 history of customer
                                    attributes (dbt_valid_from/to)
```

## Modeling decisions

**Grain of each mart model**

| Model | Grain | Key |
|---|---|---|
| `dim_customers` | one row per customer | `customer_id` |
| `dim_products` | one row per product | `product_id` |
| `fct_orders` | one row per order line | `order_id` |

The source system emits one product per order row, so `order_id` doubles as
the line key — this is documented in the model description rather than
hidden. `dim_customers` carries lifetime aggregates (`total_orders`,
`lifetime_revenue` over completed orders) so common "per customer" queries
don't need to touch the fact.

**Why a snapshot for SCD2 customer attributes**

`dim_customers` is intentionally type-1: it always reflects *current*
attributes, which is what most BI queries want, and its grain stays a clean
one-row-per-customer. Slowly changing history lives in
`snapshots/customers_snapshot.sql`, which uses the **timestamp strategy**
on `updated_at` with `unique_key = customer_id`. That keeps an auditable
`dbt_valid_from` / `dbt_valid_to` history without complicating the
dimension's joins or grain. Timestamp strategy was chosen because the source
exposes an `updated_at` column (backfilled from `signup_date` in this
synthetic extract; a real CDC feed would supply its own).

**Test strategy**

- *Staging:* `unique` + `not_null` on every primary key;
  `accepted_values` on `stg_orders.status` (`completed|refunded|cancelled`).
- *Marts:* `unique` + `not_null` on dimension/fact keys; `relationships`
  tests from `fct_orders.customer_id → dim_customers.customer_id` and
  `fct_orders.product_id → dim_products.product_id` (the seeds are generated
  with guaranteed referential integrity, so these pass).
- *Singular:* `tests/assert_order_revenue_non_negative.sql` — a business
  rule that no order line may have negative revenue; any rows returned fail
  the build.

## Tech stack

- [dbt](https://www.getdbt.com/) (`dbt-duckdb>=1.7`, which pulls a compatible `dbt-core`)
- [DuckDB](https://duckdb.org/) — local analytical database, no server needed
- Python 3.12 (only to install dbt; the project itself is pure SQL/Jinja)

## Setup + run

```bash
cd dbt-medallion-modeling

# 1. install
pip install -r requirements.txt

# 2. create your local profile from the example (gitignored)
cp profiles.yml.example profiles.yml

# 3. load seeds, build everything (models + snapshot), run tests
dbt seed && dbt build && dbt test
```

`dbt build` runs seeds, models, the snapshot and all tests in dependency
order. To inspect results:

```bash
dbt docs generate && dbt docs serve   # browse models, columns, tests, lineage
```

## Project structure

```
dbt-medallion-modeling/
├── README.md
├── requirements.txt
├── .gitignore
├── dbt_project.yml          # project + layer materializations
├── profiles.yml.example     # dev → DuckDB; prod → Snowflake (commented)
├── seeds/                   # raw_customers / raw_orders / raw_products (synthetic)
├── models/
│   ├── staging/             # bronze: stg_* views + schema.yml
│   ├── intermediate/        # silver: int_order_lines view
│   ├── marts/               # gold: dim_* / fct_* tables + schema.yml
│   └── exposures.yml        # Executive Revenue Dashboard
├── snapshots/               # customers_snapshot (SCD2)
├── macros/                  # cents_to_dollars, safe_divide
├── tests/                   # assert_order_revenue_non_negative (singular)
└── docs/
    └── style_guide.md       # naming, layering, testing, SQL conventions
```

Note: `macros/`, `tests/` and `snapshots/` live at the project root (not
under `models/`) because `dbt_project.yml` sets `macro-paths`, `test-paths`
and `snapshot-paths` there — dbt only discovers them in those paths.

## Sample outputs

After `dbt build`, the `main` schema in `retail.duckdb` contains:

- `raw_customers` (20 rows), `raw_products` (12), `raw_orders` (60) — seeds
- `stg_customers`, `stg_orders`, `stg_products` — views
- `int_order_lines` — view (60 rows)
- `dim_customers` (20 rows), `dim_products` (12), `fct_orders` (60) — tables
- `customers_snapshot` — SCD2 table with `dbt_valid_from` / `dbt_valid_to`

Example: top categories by completed-order revenue

```sql
select
    p.category,
    round(sum(f.line_revenue), 2) as revenue_dollars
from main.fct_orders as f
join main.dim_products as p using (product_id)
where f.status = 'completed'
group by 1
order by 2 desc;
```

## Notes

- Everything under `seeds/` is synthetic and deterministic (generated with a
  fixed random seed). Names, emails and cities are invented.
- `profiles.yml.example` contains **placeholder** Snowflake settings only —
  no real account, user or password exists in this repo.
