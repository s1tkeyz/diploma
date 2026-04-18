{% macro anon_pii(field, pii_type, strategy, args) %}
    {% if strategy == 'mask' %}
        {% set keep_joinable = args.get('PII_KEEP_JOINABLE', false) %}
        {{ dbt_pii_guard.mask_pii(field, pii_type, keep_joinable) }}

    {% elif strategy == 'fill' %}
        {% set fill_type = args.get('PII_FILL_TYPE', none) %}
        {{ dbt_pii_guard.require_keys(args, ['PII_FILL_VALUE']) }}
        {% set fill_val = args.get('PII_FILL_VALUE') %}
        {{ dbt_pii_guard.fill_pii(field, fill_val, fill_type) }}

    {% elif strategy == 'trunc' %}
        {% set mode = args.get('PII_TRUNC_MODE', 'month') %}
        {{ dbt_pii_guard.trunc_pii(field, pii_type, mode) }}

    {% elif strategy == 'binarize' %}
        {% set n_bins = args.get('PII_N_BINS', 5) %}
        {% set fill_type = args.get('PII_FILL_TYPE', 'bin') %}
        {{ dbt_pii_guard.binarize_pii(field, n_bins, fill_type) }}

    {% elif strategy == 'scale' %}
        {{ dbt_pii_guard.scale_pii(field) }}

    {% elif strategy == 'hash' %}
        {{ dbt_pii_guard.hash_pii(field) }}

    {% else %}
        {{ exceptions.raise_compiler_error("Неизвестный тип ПДн: " ~ pii_type) }}

    {% endif %}
{% endmacro %}
