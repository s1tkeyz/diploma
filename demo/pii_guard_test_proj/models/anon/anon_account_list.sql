{{
    config(materialized='pii_anon_table')
}}

select
    owner_inn,
    account_number,
    is_active
from
    {{ ref('stage_accounts') }}
    