{% materialization pii_anon_table, default %}
    {# 1. Получаем отношения через современный adapter API #}
    {% set existing_relation = adapter.get_relation(database=this.database, schema=this.schema, identifier=this.identifier) %}
    {% set target_relation = this.incorporate(type='table') %}

    {# Поддержка обмена таблиц без дампинга (только для PG/Greenplum) #}
    {% set can_exchange = target_relation.type == 'table' and target.type in ('postgres', 'greenplum', 'postgresql') %}
    {% set intermediate_relation = make_intermediate_relation(target_relation) %}
    {% set preexisting_intermediate_relation = adapter.get_relation(
        database=intermediate_relation.database, 
        schema=intermediate_relation.schema, 
        identifier=intermediate_relation.identifier
    ) %}

    {% set backup_relation = none %}
    {% if can_exchange and existing_relation %}
        {% set backup_relation = make_backup_relation(target_relation, 'table') %}
    {% endif %}
    {% set preexisting_backup_relation = adapter.get_relation(
        database=backup_relation.database, 
        schema=backup_relation.schema, 
        identifier=backup_relation.identifier
    ) if backup_relation else none %}

    {% set grant_config = config.get('grants') %}

    {# 2. Очистка временных объектов #}
    {{ drop_relation_if_exists(preexisting_intermediate_relation) }}
    {{ drop_relation_if_exists(preexisting_backup_relation) }}

    {{ run_hooks(pre_hooks, inside_transaction=False) }}
    {{ run_hooks(pre_hooks, inside_transaction=True) }}

    {# 3. Парсинг метаданных и формирование SELECT #}
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

    {# 4. Создание промежуточной таблицы #}
    {% call statement('main') %}
        {{ get_create_table_as_sql(False, intermediate_relation, wrapped_sql) }}
    {% endcall %}

    {# 5. Атомарная замена (swap) #}
    {% if existing_relation and backup_relation %}
        {{ adapter.rename_relation(existing_relation, backup_relation) }}
    {% endif %}
    {{ adapter.rename_relation(intermediate_relation, target_relation) }}

    {# 6. Аудит и подсчёт строк (совместим с dbt >= 1.5) #}
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

    {# 7. Пост-хуки, гранты, документация #}
    {{ run_hooks(post_hooks, inside_transaction=True) }}
    {% set should_revoke = should_revoke(existing_relation, full_refresh_mode=True) %}
    {% do apply_grants(target_relation, grant_config, should_revoke=should_revoke) %}
    {% do persist_docs(target_relation, model) %}

    {# 8. Коммит и очистка бэкапа #}
    {% if target.type in ('postgres', 'greenplum', 'postgresql') %}
        {{ adapter.commit() }}
    {% endif %}

    {% if backup_relation %}
        {{ drop_relation_if_exists(backup_relation) }}
    {% endif %}

    {{ run_hooks(post_hooks, inside_transaction=False) }}
    {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}