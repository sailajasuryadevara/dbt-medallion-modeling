{{
    config(
        materialized='table',
        description='Gold layer: customer dimension, one row per customer.'
    )
}}

with customers as (

    select * from {{ ref('stg_customers') }}

),

order_stats as (

    select
        customer_id,
        count(*) as total_orders,
        sum(
            case when status = 'completed' then line_revenue else 0 end
        ) as lifetime_revenue,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date

    from {{ ref('int_order_lines') }}
    group by customer_id

)

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.city,
    c.state,
    c.signup_date,
    coalesce(s.total_orders, 0) as total_orders,
    coalesce(s.lifetime_revenue, 0.0) as lifetime_revenue,
    s.first_order_date,
    s.last_order_date

from customers as c
left join order_stats as s
    on c.customer_id = s.customer_id
