{% macro hash_pii(field) %}
    {{ adapter.dispatch('hash_pii', 'dbt_pii_guard')(field) }}
{% endmacro %}

{% macro default__hash_pii(field) %}
    {{ dbt_pii_guard.arenadatadb__hash_pii(field) }}
{% endmacro %}

{% macro arenadatadb__hash_pii(field) %}
    {% set salt = env_var('DBT_PII_GUARD_HASH_SALT', '') %}
    {% if salt == '' %}
        {{ exceptions.warn('Переменная окружения DBT_PII_GUARD_HASH_SALT не установлена. Хеширование небезопасно') }}
    {% endif %}

    case
        when {{ field }} is not null then
            upper(encode(sha256((lower(trim({{ field }}::text)) || '{{ salt }}')::bytea), 'hex'))::char(64)
        else null
    end as {{ field }}
{% endmacro %}