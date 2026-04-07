{% macro shuffle_pii(field) %}
    {{ adapter.dispatch('shuffle_pii', 'dbt_pii_guard')(field) }}
{% endmacro %}

{% macro default__shuffle_pii(field) %}
    {{ dbt_pii_guard.arenadatadb__shuffle_pii(field) }}
{% endmacro %}

{% macro arenadatadb__shuffle_pii(field) %}
    (ARRAY_AGG({{ field }} ORDER BY RANDOM()) OVER ())[ROW_NUMBER() OVER ()]
{% endmacro %}