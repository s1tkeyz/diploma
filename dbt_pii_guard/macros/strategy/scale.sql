{% macro scale_pii(field) %}
    {{ adapter.dispatch('scale_pii', 'dbt_pii_guard')(field) }}
{% endmacro %}

{% macro default__scale_pii(field) %}
    {{ dbt_pii_guard.arenadatadb__scale_pii(field) }}
{% endmacro %}

{% macro arenadatadb__scale_pii(field) %}
    case
        when {{ field }} is not null then
            ({{ field }}::numeric - min({{ field }}::numeric) over ()) / nullif(max({{ field }}::numeric) over () - min({{ field }}::numeric) over (), 0)
        else null
    end as {{ field }}  
{% endmacro %}