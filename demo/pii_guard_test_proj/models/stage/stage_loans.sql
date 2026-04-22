select
    c.snils,
    c.inn,
    l.start_date,
    l.end_date,
    l.percent_value,
    l.amount,
    l.currency
from
    {{ source('srcdata', 't_loan_data') }} l
    join {{ source('srcdata', 't_client_data') }} c using (client_id)