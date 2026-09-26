{{
    config(
        materialized='table',
        description='Gold layer: order fact. Grain: one row per order line.'
    )
}}

with lines as (

    select * from {{ ref('int_order_lines') }}

)

select
    -- Grain: one row per order line. The source system emits one product
    -- per order row, so order_id is the line key in this dataset.
    order_id,
    customer_id,
    product_id,
    quantity,
    unit_price_dollars,
    line_revenue,
    -- Share of this line within its order; safe_divide guards the
    -- degenerate zero-revenue case instead of erroring.
    {{
        safe_divide(
            'line_revenue',
            'sum(line_revenue) over (partition by order_id)'
        )
    }} as revenue_share_of_order,
    order_date,
    status

from lines
