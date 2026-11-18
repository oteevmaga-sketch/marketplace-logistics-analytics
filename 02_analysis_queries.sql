-- Marketplace Logistics Analytics
-- Аналитические запросы для PostgreSQL.
-- Перед выполнением импортируйте orders.csv в public.orders.

-- 1. Проверка количества строк и уникальности заказов.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM public.orders;

-- 2. Общие показатели: заказы, доставки, отмены и доля доставок вовремя.
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status = 'Доставлен') AS delivered_orders,
    COUNT(*) FILTER (WHERE status = 'Отменён') AS cancelled_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE on_time = 'Да')
        / NULLIF(COUNT(*) FILTER (WHERE status = 'Доставлен'), 0),
        2
    ) AS on_time_delivery_pct
FROM public.orders;

-- 3. Среднее время доставки (только доставленные заказы).
SELECT
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM public.orders
WHERE status = 'Доставлен';

-- 4. Средняя задержка среди заказов, доставленных с опозданием.
SELECT
    ROUND(AVG(delay_days), 2) AS avg_delay_days
FROM public.orders
WHERE status = 'Доставлен'
  AND delay_days > 0;

-- 5. Сравнение складов по объёму и своевременности доставки.
SELECT
    warehouse_name,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE status = 'Доставлен') AS delivered_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE on_time = 'Да')
        / NULLIF(COUNT(*) FILTER (WHERE status = 'Доставлен'), 0),
        2
    ) AS on_time_pct,
    ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0), 2) AS avg_delay_days
FROM public.orders
GROUP BY warehouse_name
ORDER BY on_time_pct ASC;

-- 6. Сравнение регионов покупателей по доле задержанных доставок.
SELECT
    region,
    COUNT(*) FILTER (WHERE delay_days > 0) AS delayed_orders,
    COUNT(*) FILTER (WHERE status = 'Доставлен') AS delivered_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE delay_days > 0)
        / NULLIF(COUNT(*) FILTER (WHERE status = 'Доставлен'), 0),
        2
    ) AS delay_pct
FROM public.orders
GROUP BY region
ORDER BY delay_pct DESC;

-- 7. Динамика заказов по месяцам.
SELECT
    DATE_TRUNC('month', order_date)::date AS month,
    COUNT(*) AS orders_count,
    COUNT(*) FILTER (WHERE status = 'Доставлен') AS delivered_count,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM public.orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- 8. Рейтинг складов по доле доставок вовремя (оконная функция).
WITH warehouse_kpi AS (
    SELECT
        warehouse_name,
        100.0 * COUNT(*) FILTER (WHERE on_time = 'Да')
        / NULLIF(COUNT(*) FILTER (WHERE status = 'Доставлен'), 0) AS on_time_pct
    FROM public.orders
    GROUP BY warehouse_name
)
SELECT
    warehouse_name,
    ROUND(on_time_pct, 2) AS on_time_pct,
    DENSE_RANK() OVER (ORDER BY on_time_pct DESC) AS warehouse_rank
FROM warehouse_kpi
ORDER BY warehouse_rank;

-- 9. Примеры проблемных заказов с самой большой задержкой.
SELECT
    order_id,
    warehouse_name,
    region,
    promised_delivery_date,
    actual_delivery_date,
    delay_days
FROM public.orders
WHERE delay_days > 0
ORDER BY delay_days DESC, order_date
LIMIT 20;
