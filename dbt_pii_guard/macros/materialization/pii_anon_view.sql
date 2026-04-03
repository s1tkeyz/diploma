{% materialization pii_anon_view, default %}
    {% set existing_relation = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) %}
    {% set target_relation = this.incorporate(type='view') %}

    {% set grant_config = config.get('grants') %}

    {{ run_hooks(pre_hooks, inside_transaction=False) }}
    {{ run_hooks(pre_hooks, inside_transaction=True) }}

    {% set final_columns = [] %}
    {% set audit_records = [] %}
    {% set columns_config = model.columns or {} %}

    {% for column_name, column_props in columns_config.items() %}
        {% set meta = column_props.get('meta', {}) %}
        {% set pii_type = meta.get('PII_TYPE') %}
        {% set strategy = meta.get('PII_STRATEGY') %}
        
        {% if pii_type and strategy %}
            {% set pii_meta = {} %}
            {% for k, v in meta.items() if k.startswith('PII_') %}
                {% do pii_meta.update({k: v}) %}
            {% endfor %}
            {% do final_columns.append(dbt_pii_guard.anon_pii(column_name, pii_type, strategy, pii_meta)) %}
            {% do audit_records.append({'field': column_name, 'strategy': strategy}) %}
        {% else %}
            {% do final_columns.append(column_name) %}
        {% endif %}
    {% endfor %}

    {% set select_clause = "select " ~ final_columns | join(', ') %}
    {% set wrapped_sql = "with source_data as (" ~ sql ~ ") " ~ select_clause ~ " from source_data" %}

    {{ drop_relation_if_exists(existing_relation) }}

    {% call statement('main') %}
        {{ get_create_view_as_sql(target_relation, wrapped_sql) }}
    {% endcall %}

    {% if audit_records %}
        {% set count_sql %}SELECT COUNT(*) as cnt FROM {{ target_relation }}{% endset %}
        {% set count_result = run_query(count_sql) %}
        {% if count_result and count_result.rows | length > 0 %}
            {% set rows_count = count_result.rows[0]['cnt'] | int %}
        {% else %}
            {% set rows_count = 0 %}
        {% endif %}

        {% for record in audit_records %}
            {% do dbt_pii_guard.audit_log(
                model_name=target_relation.identifier,
                field_name=record.field,
                strategy=record.strategy,
                rows_processed=rows_count
            ) %}
        {% endfor %}
    {% endif %}

    {{ run_hooks(post_hooks, inside_transaction=True) }}
    {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
    {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}
    {% do persist_docs(target_relation, model) %}

    {% if target.type in ('postgres', 'greenplum', 'postgresql') %}
        {{ adapter.commit() }}
    {% endif %}

    {{ run_hooks(post_hooks, inside_transaction=False) }}
    {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}