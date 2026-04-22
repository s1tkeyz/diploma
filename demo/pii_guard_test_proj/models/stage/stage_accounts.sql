select 
    c.inn as owner_inn,
    a.account_number,
    case
        when a.end_date is null then true
        else false
    end as is_active
from
    {{ source('srcdata', 't_client_account') }} l
    join {{ source('srcdata', 't_account_data') }} a using (account_id)
    join {{ source('srcdata', 't_client_data') }} c using (client_id)

