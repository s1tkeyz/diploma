{% macro discretize_pii(field, n_bins, fill_type) %}
    {{ adapter.dispatch('discretize_pii', 'dbt_pii_guard')(field, n_bins, fill_type) }}
{% endmacro %}

{% macro default__discretize_pii(field, n_bins, fill_type) %}
    {{ dbt_pii_guard.arenadatadb__discretize_pii(field, n_bins, fill_type) }}
{% endmacro %}

{% macro arenadatadb__discretize_pii(field, n_bins, fill_type) %}
    {% set col = field | trim %}
    {% set nbins = n_bins | int %}

    {% if nbins < 2 %}
        {{ exceptions.raise_compiler_error('количество бинов должно быть не менее 2') }}
    {% endif %}

    {% set min_val = 'min({}::numeric) over ()'.format(col) %}
    {% set max_val = 'max({}::numeric) over ()'.format(col) %}
    {% set step = '({} - {}) / nullif({}, 0)'.format(max_val, min_val, nbins) %}
    {% set bin_idx = 'least(greatest(width_bucket({}::numeric, {}, {}, {}), 1), {})'.format(col, min_val, max_val, nbins, nbins) %}
    {% set b_min = '{} + ({} - 1) * {}'.format(min_val, bin_idx, step) %}
    {% set b_max = '{} + {} * {}'.format(min_val, bin_idx, step) %}

    {% if fill_type == 'drop' %}
        {# колонка исключена из выборки #}
    {% elif fill_type == 'bin' %}
        case when {{ col }} is null then null else {{ bin_idx }} end as {{ col }},
    {% elif fill_type == 'avg' %}
        case when {{ col }} is null then null else ({{ b_min }} + {{ b_max }}) / 2.0 end as {{ col }},
    {% else %}
        {{ exceptions.raise_compiler_error('неподдерживаемый тип заполнения: ' ~ fill_type) }}
    {% endif %}

    case when {{ col }} is null then null else {{ b_min }} end as {{ col }}_bin_min,
    case when {{ col }} is null then null else {{ b_max }} end as {{ col }}_bin_max
{% endmacro %}