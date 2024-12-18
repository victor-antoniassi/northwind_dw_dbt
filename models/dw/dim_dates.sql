{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH date_bounds AS (
    -- Encontra o intervalo de datas necessário
    SELECT
        MIN(order_date) as min_date,
        MAX(order_date) as max_date
    FROM {{ ref('stg_orders') }}
),

date_sequence AS (
    -- Gera sequência de datas
    SELECT DATEADD(DAY, seq, min_date) as date
    FROM date_bounds,
        (SELECT ROW_NUMBER() OVER (ORDER BY 1) - 1 as seq 
         FROM {{ ref('stg_orders') }} 
         LIMIT (SELECT DATEDIFF('day', min_date, max_date) + 1 FROM date_bounds))
),

date_metrics AS (
    -- Precalcula métricas de pedidos por data
    SELECT 
        order_date,
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as total_customers,
        SUM(freight) as total_freight
    FROM {{ ref('stg_orders') }}
    GROUP BY order_date
)

SELECT
    -- Data como chave
    date as date_id,
    -- Componentes da data
    EXTRACT(YEAR FROM date) as year,
    EXTRACT(MONTH FROM date) as month,
    EXTRACT(DAY FROM date) as day,
    EXTRACT(DOW FROM date) as day_of_week,
    EXTRACT(QUARTER FROM date) as quarter,
    -- Descritivos
    TO_CHAR(date, 'Month') as month_name,
    CASE EXTRACT(DOW FROM date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
    -- Flags úteis
    CASE 
        WHEN EXTRACT(DOW FROM date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END as is_weekend,
    CASE 
        WHEN date = DATE_TRUNC('month', date) THEN 'First Day'
        WHEN date = LAST_DAY(date) THEN 'Last Day'
        ELSE 'Other'
    END as month_day_type,
    -- Métricas diárias
    COALESCE(dm.total_orders, 0) as total_orders,
    COALESCE(dm.total_customers, 0) as total_customers,
    COALESCE(dm.total_freight, 0) as total_freight
FROM date_sequence ds
LEFT JOIN date_metrics dm ON ds.date = dm.order_date