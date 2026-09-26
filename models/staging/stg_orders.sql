{{
    config(
        materialized='view',
        description='Bronze layer: cleaned order records, one row per order.'
    )
}}

with source as (

    select * from {{ ref('raw_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,
        product_id,
        cast(quantity as integer) as quantity,
        {{ cents_to_dollars('unit_price_cents') }} as unit_price_dollars,
        cast(order_date as date) as order_date,
        lower(status) as status

    from source

)

select * from renamed
