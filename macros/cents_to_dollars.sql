{#--
    cents_to_dollars(column_name)

    Converts a monetary amount stored as an integer number of cents into
    dollars. Casts to double first so integer division never truncates.

    Args:
        column_name: name (or expression) of the cents column.

    Usage:
        {{ cents_to_dollars('unit_price_cents') }} as unit_price_dollars
--#}
{% macro cents_to_dollars(column_name) %}
    cast({{ column_name }} as double) / 100.0
{% endmacro %}
