select 
    account_number,
    {{ dbt_pii_guard.binarize_pii('amount', 5, 'avg') }}
from
    {{ source('srcdata', 't_account_data') }} l