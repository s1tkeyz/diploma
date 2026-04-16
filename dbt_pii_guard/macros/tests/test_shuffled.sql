{% test assert_all_values_shuffled(model, unique_key, original_column, shuffled_column) %}
select
    {{ unique_key }} as pk,
    {{ original_column }} as original_val,
    {{ shuffled_column }} as shuffled_val
from {{ model }}
where {{ original_column }} is not distinct from {{ shuffled_column }}
{% endtest %}