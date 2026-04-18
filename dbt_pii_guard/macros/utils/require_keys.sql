{% macro require_keys(dict, required_keys) %}
    {% for key in required_keys %}
        {% if key not in dict %}
            {{ exceptions.raise_compiler_error("Отсутствует необходимый ключ: " ~ key) }}
        {% endif %}
    {% endfor %}
{% endmacro %}