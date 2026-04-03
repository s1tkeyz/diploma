{% macro trunc_pii(field, pii_type, mode) %}
    {{ adapter.dispatch('trunc_pii', 'dbt_pii_guard')(field, pii_type, mode) }}
{% endmacro %}

{% macro default__trunc_pii(field, pii_type, mode) %}
    {{ dbt_pii_guard.arenadatadb__trunc_pii(field, pii_type, mode) }}
{% endmacro %}

{% macro arenadatadb__trunc_pii(field, pii_type, mode) %}
    {% if pii_type != 'date' %}
        {{ exceptions.raise_compiler_error("Обрезка ПДн поддерживает только даты") }}
    {% endif %}

    case
        when {{ field }} is not null then
            {% if mode == 'month' %}
                date_trunc('month', {{ field }})
            {% elif mode == 'year' %}
                date_trunc('year', {{ field }})
            {% elif mode == 'quarter' %}
                to_char({{ field }}, 'YYYY "Q"Q')
            {% else %}
                {{ exceptions.raise_compiler_error("Неизвестный режим обрезки") }}
            {% endif %}
        else null
    end as {{ field }}
{% endmacro %}