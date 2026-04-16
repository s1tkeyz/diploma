{% test l_diversity(model, quasi_identifiers, sensitive_column, l_value) %}
with grouped_data as (
    select
        {{ quasi_identifiers }},
        count(distinct {{ sensitive_column }}) as distinct_sensitive
    from {{ model }}
    group by {{ quasi_identifiers }}
)
select
    {{ quasi_identifiers }},
    distinct_sensitive
from grouped_data
where distinct_sensitive < {{ l_value }}
{% endtest %}