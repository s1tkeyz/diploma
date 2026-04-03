{% macro fill_pii(field, fill_val, fill_type) %}
    {{ adapter.dispatch('fill_pii', 'dbt_pii_guard')(field, fill_val, fill_type) }}
{% endmacro %}

{% macro default__fill_pii(field, fill_val, fill_type) %}
    {{ dbt_pii_guard.arenadatadb__fill_pii(field, fill_val, fill_type) }}
{% endmacro %}

{% macro arenadatadb__fill_pii(field, fill_val, fill_type) %}
    case
        when {{ field }} is not null then
            '{{ fill_val }}' {% if fill_type %}::{{ fill_type }}{% endif %}
        else null
    end as {{ field }}
{% endmacro %}