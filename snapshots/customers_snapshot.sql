{% snapshot customers_snapshot %}

{{
    config(
        target_schema=target.schema,
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
    )
}}

/*
  SCD Type 2 history of customer attributes.

  Why a snapshot instead of rebuilding dim_customers from history?
  dim_customers is a type-1 dimension: it always shows the *current*
  attributes plus lifetime aggregates, which is what most BI queries want.
  The snapshot keeps a full, auditable change history (dbt_valid_from /
  dbt_valid_to / dbt_updated_at) without complicating the dimension's
  grain or its joins. Timestamp strategy is used because the source
  exposes an updated_at column; with a real CDC feed this column would
  come from the source system instead of being backfilled.
*/

select * from {{ ref('stg_customers') }}

{% endsnapshot %}
