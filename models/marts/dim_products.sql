{{
    config(
        materialized='table',
        description='Gold layer: product dimension, one row per product.'
    )
}}

select
    product_id,
    product_name,
    category,
    unit_price_dollars

from {{ ref('stg_products') }}
