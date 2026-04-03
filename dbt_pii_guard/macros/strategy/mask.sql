{% macro mask_pii(field, pii_type, keep_joinable) %}
    {{ adapter.dispatch('mask_pii', 'dbt_pii_guard')(field, pii_type, keep_joinable) }}
{% endmacro %}

{% macro default__mask_pii(field, pii_type, keep_joinable) %}
    {{ dbt_pii_guard.arenadatadb__mask_pii(field, pii_type, keep_joinable) }}
{% endmacro %}

{% macro arenadatadb__mask_pii(field, pii_type, keep_joinable) %}
    case
        when {{ field }} is not null then
            {% if pii_type == 'inn' %}
                concat(left({{ field }}, 4), '********')::char(12)

            {% elif pii_type == 'fio' %}
                regexp_replace({{ field }}, '([А-Яа-яёЁ])([А-Яа-яёЁ]*)', '\1**', 'g')::char(11)

            {% elif pii_type == 'snils' %}
                concat('***-***-*** ', right({{ field }}, 2))::char(14)

            {% elif pii_type == 'phone' %}
                regexp_replace({{ field }}, '^(\+7|8)\((\d+)\)\d{3}-\d{2}-\d{2}$', '\1(\2)***-**-**') 

            {% elif pii_type == 'email' %}
                regexp_replace({{ field }}, '^(.)(.*)(.)@', '\1**\3@')

            {% elif pii_type == 'card_number' %}
                concat(
                    left({{ field }}, 6),
                    '** **** ',
                    right({{ field }}, 4)
                )::char(19)

            {% elif pii_type == 'account_number' %}
                {% set masks = run_query("select acc_type, mask from dbt_pii_guard.t_acc_num_masks") %}
                {% set default_mask = '_____________*******' %}

                {% if masks | length == 0 %}
                concat(
                    {% for i in range(1, 21) %}
                    {% if default_mask[i-1] == '_' %}substr({{ field }}, {{ i }}, 1){% else %}'*'{% endif %}{% if not loop.last %}, {% endif %}
                    {% endfor %}
                )::char(20)

                {% else %}
                case
                {% for row in masks %}
                when left({{ field }}, 5) = '{{ row.acc_type }}' then
                    concat(
                    {% for i in range(1, 21) %}
                        {% if row.mask[i-1] == '_' %}substr({{ field }}, {{ i }}, 1){% else %}'*'{% endif %}{% if not loop.last %}, {% endif %}
                    {% endfor %}
                    )
                {% endfor %}
                else
                    concat(
                    {% for i in range(1, 21) %}
                        {% if default_mask[i-1] == '_' %}substr({{ field }}, {{ i }}, 1){% else %}'*'{% endif %}{% if not loop.last %}, {% endif %}
                    {% endfor %}
                    )
                end::char(20)
                {% endif %}

            {% elif pii_type == 'passport_number' %}
                regexp_replace({{ field }}, '^(\d{4}) (\d{6})$', '\1 ******')::char(11)

            {% else %}
                {{ exceptions.raise_compiler_error("Указанный тип ПДн " ~ pii_type ~ " не поддерживает маскирование в ArenadataDB") }}

            {% endif %}
            {% if keep_joinable %} || upper(encode(sha256((lower(trim(account_number::text)) || '')::bytea), 'hex'))::char(64) {% endif %}
        else null
    end as {{ field }}
{% endmacro %}