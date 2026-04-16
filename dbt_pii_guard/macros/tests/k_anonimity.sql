{% test k_anonymity(model, quasi_identifiers, k_value) %}
with grouped_data as (
    select
        {{ quasi_identifiers }},
        count(*) as group_size
    from {{ model }}
    group by {{ quasi_identifiers }}
)
select 
    {{ quasi_identifiers }},
    group_size
from grouped_data
where group_size < {{ k_value }}
{% endtest %}