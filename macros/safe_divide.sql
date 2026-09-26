{#--
    safe_divide(numerator, denominator)

    Division that returns NULL instead of raising a division-by-zero error
    when the denominator is NULL or zero. Both arguments may be column names
    or arbitrary SQL expressions.

    Args:
        numerator:   dividend column or expression.
        denominator: divisor column or expression.

    Usage:
        {{ safe_divide('line_revenue', 'order_revenue') }} as revenue_share
--#}
{% macro safe_divide(numerator, denominator) %}
    case
        when {{ denominator }} is null or {{ denominator }} = 0 then null
        else cast({{ numerator }} as double) / cast({{ denominator }} as double)
    end
{% endmacro %}
