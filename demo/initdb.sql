create table srcdata.t_client_data (
	client_id bigint generated always as identity primary key,
	fio varchar(128),
	snils varchar(14),
	inn varchar(12)
);

create table srcdata.t_loan_data (
	loan_id bigint generated always as identity primary key,
	client_id bigint references srcdata.t_client_data (client_id),
	amount money,
	percent_value float,
	currency varchar(3),
	start_date date,
	end_date date
);

create table srcdata.t_account_data (
	account_id bigint generated always as identity primary key,
	account_number varchar(20),
	amount money,
	start_date date,
	end_date date
);

create table srcdata.t_transactions (
	transaction_id bigint generated always as identity primary key,
	datetime timestamp,
	acc_from_id bigint references srcdata.t_account_data (account_id),
	acc_to_id bigint references srcdata.t_account_data (account_id),
	amount money
);

create table srcdata.t_client_account (
	client_id bigint references srcdata.t_client_data (client_id),
	account_id bigint references srcdata.t_account_data (account_id)
);

create table if not exists dbt_pii_guard.audit_log (
    run_id VARCHAR(255),
    timestamp TIMESTAMP,
    model_name VARCHAR(255),
    field_name VARCHAR(255),
    strategy VARCHAR(100),
    rows_processed BIGINT,
    dbt_environment VARCHAR(50)
);

create table if not exists dbt_pii_guard.t_acc_num_masks (
	acc_type char(5),
	mask char(20)
);