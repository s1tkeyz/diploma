select
    a1.account_number as account_from,
    a2.account_number as account_to,
    t.amount,
    'RUR' as currency,
    t.datetime
from
    {{ source('srcdata', 't_transactions') }} t
    join {{ source('srcdata', 't_account_data') }} a1 on (t.acc_from_id = a1.account_id)
    join {{ source('srcdata', 't_account_data') }} a2 on (t.acc_to_id = a2.account_id)
