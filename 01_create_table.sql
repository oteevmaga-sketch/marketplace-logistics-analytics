-- Marketplace Logistics Analytics
-- PostgreSQL 18
-- Выполнить один раз в базе marketplace_analytics.

CREATE TABLE IF NOT EXISTS public.orders (
    order_id TEXT PRIMARY KEY,
    order_date DATE NOT NULL,
    region TEXT,
    warehouse_id TEXT,
    warehouse_name TEXT,
    warehouse_region TEXT,
    order_amount_rub NUMERIC(12, 2),
    promised_delivery_date DATE,
    actual_delivery_date DATE,
    status TEXT,
    delivery_days NUMERIC(5, 1),
    delay_days NUMERIC(5, 1),
    on_time TEXT
);

-- После выполнения скрипта импортируйте orders.csv в public.orders через pgAdmin.
-- CSV: UTF-8, Header = Yes, Delimiter = comma, Quote = double quote.
