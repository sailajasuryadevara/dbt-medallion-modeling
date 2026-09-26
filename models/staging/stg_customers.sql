{{
    config(
        materialized='view',
        description='Bronze layer: cleaned customer records, one row per customer.'
    )
}}

with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        email,
        city,
        state,
        cast(signup_date as date) as signup_date,
        -- The synthetic extract has no change-data-capture feed, so we
        -- backfill updated_at from signup_date. A real CDC source would
        -- supply its own last-modified timestamp here; the snapshot
        -- (snapshots/customers_snapshot.sql) keys its SCD2 logic off
        -- this column.
        cast(signup_date as timestamp) as updated_at

    from source

)

select * from renamed
