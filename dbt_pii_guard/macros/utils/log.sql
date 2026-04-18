{% macro log_run(model_name, field_name, method) %}
    {% set msg = "[PII_GUARD][" ~ invocation_id ~ "](" ~ model_name ~ "." ~ field_name ~ ")(" ~ method ~ ")" %}
    {% do log(msg, info=True) %}
{% endmacro %}

{% macro audit_log(model_name, field_name, strategy, rows_processed=none) %}
    {% if not model_name or not field_name or not strategy %}
        {% do exceptions.raise_compiler_error("audit_log: параметры model_name, field_name и strategy обязательны.") %}
    {% endif %}

    {% set safe_details = details | replace("'", "''") %}
    {% set rows_val = rows_processed if rows_processed is not none else 'NULL' %}

    {% set audit_sql %}
        insert into dbt_pii_guard.audit_log (
            run_id, timestamp, model_name, field_name,
            strategy, rows_processed, dbt_environment
        ) values (
            '{{ invocation_id }}',
            CURRENT_TIMESTAMP,
            '{{ model_name }}',
            '{{ field_name }}',
            '{{ strategy }}',
            {{ rows_val }},
            '{{ target.name }}'
        )
    {% endset %}

    {% do run_query(audit_sql) %}
{% endmacro %}