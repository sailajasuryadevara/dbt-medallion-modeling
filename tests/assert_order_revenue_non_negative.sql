-- Singular test: order-line revenue must never be negative.
-- This query must return zero rows; any rows returned fail the test.

select
    order_id,
    customer_id,
    product_id,
    line_revenue

from {{ ref('fct_orders') }}

where line_revenue < 0
