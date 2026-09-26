{{
    config(
        materialized='view',
        description='Silver layer: one row per order line. Orders joined to the product catalog with line-level revenue.'
    )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

),

products as (

    select * from {{ ref('stg_products') }}

)

select
    o.order_id,
    o.customer_id,
    o.product_id,
    p.product_name,
    p.category,
    o.quantity,
    o.unit_price_dollars,
    -- Line-level revenue: quantity x unit price. This is the core
    -- conformed measure every downstream mart reuses.
    o.quantity * o.unit_price_dollars as line_revenue,
    o.order_date,
    o.status

from orders as o
inner join products as p
    on o.product_id = p.product_id
