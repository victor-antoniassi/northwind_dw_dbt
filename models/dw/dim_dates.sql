{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH 
date_bounds AS (
    -- Encontra o intervalo de datas necessário
    SELECT
        MIN(order_date) as min_date,
        MAX(order_date) as max_date
    FROM {{ ref('stg_orders') }}
),

date_sequence AS (
    SELECT 
        UNNEST(generate_series(
            (SELECT min_date FROM date_bounds),
            (SELECT max_date FROM date_bounds),
            INTERVAL '1' DAY
        )) AS date
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
    ds.date AS date_id,
    
    -- Componentes da data
    EXTRACT(YEAR FROM ds.date) AS year,
    EXTRACT(MONTH FROM ds.date) AS month,
    EXTRACT(DAY FROM ds.date) AS day,
    EXTRACT(DOW FROM ds.date) AS day_of_week,
    EXTRACT(QUARTER FROM ds.date) AS quarter,
    
    -- Descritivos
    strftime('%B', ds.date) AS month_name,  -- Usando strftime para o nome do mês
    CASE EXTRACT(DOW FROM ds.date)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    
    -- Flags úteis
    CASE 
        WHEN EXTRACT(DOW FROM ds.date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS is_weekend,
    
    CASE 
        WHEN ds.date = DATE_TRUNC('month', ds.date) THEN 'First Day'  -- Garantir que ds.date seja DATE
        WHEN ds.date = LAST_DAY(ds.date) THEN 'Last Day'
        ELSE 'Other'
    END AS month_day_type,
    
    -- Métricas diárias
    COALESCE(dm.total_orders, 0) AS total_orders,
    COALESCE(dm.total_customers, 0) AS total_customers,
    COALESCE(dm.total_freight, 0) AS total_freight
FROM date_sequence ds
LEFT JOIN date_metrics dm ON ds.date = dm.order_date