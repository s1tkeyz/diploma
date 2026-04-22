select 
    account_number,
    {{ dbt_pii_guard.scale_pii('amount') }}
from
    {{ source('srcdata', 't_account_data') }} l