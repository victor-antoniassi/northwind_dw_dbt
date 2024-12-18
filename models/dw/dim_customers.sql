{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH customer_orders AS (
    -- Precalcula todas as métricas de pedidos em uma única passagem
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) as total_orders,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date,
        AVG(
            COALESCE(
                (SELECT SUM(unit_price * quantity * (1-discount))
                FROM {{ ref('stg_order_details') }} od 
                WHERE od.order_id = o.order_id), 
            0)
        ) as avg_order_value
    FROM {{ ref('stg_orders') }} o
    GROUP BY customer_id
)

SELECT
    -- Chave primeiro
    c.customer_id,
    -- Informações do cliente
    c.company_name,
    c.contact_name,
    c.contact_title,
    -- Endereço
    c.address,
    c.city,
    c.region,
    c.postal_code,
    c.country,
    -- Contato
    c.phone,
    c.fax,
    -- Métricas de pedidos
    COALESCE(co.total_orders, 0) as total_orders,
    co.first_order_date,
    co.last_order_date,
    COALESCE(co.avg_order_value, 0) as avg_order_value,
    -- Status calculado
    CASE 
        WHEN co.last_order_date IS NULL THEN 'New'
        WHEN co.last_order_date <= DATEADD(MONTH, -6, CURRENT_DATE) THEN 'Churned'
        WHEN co.last_order_date <= DATEADD(MONTH, -3, CURRENT_DATE) THEN 'At Risk'
        ELSE 'Active'
    END as customer_status
FROM {{ ref('stg_customers') }} c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id