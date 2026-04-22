select
    fio,
    snils,
    inn,
    '1993-03-17'::date as birth_date
from {{ source('srcdata', 't_client_data') }}