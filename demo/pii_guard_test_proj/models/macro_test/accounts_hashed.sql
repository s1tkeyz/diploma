select 
    {{ dbt_pii_guard.hash_pii('owner_inn') }},
    account_number,
    is_active
from {{ ref('stage_accounts') }}