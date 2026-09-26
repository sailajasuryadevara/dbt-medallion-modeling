{{
    config(
        materialized='view',
        description='Bronze layer: cleaned product catalog, one row per product.'
    )
}}

with source as (

    select * from {{ ref('raw_products') }}

),

renamed as (

    select
        product_id,
        product_name,
        category,
        {{ cents_to_dollars('unit_price_cents') }} as unit_price_dollars

    from source

)

select * from renamed
