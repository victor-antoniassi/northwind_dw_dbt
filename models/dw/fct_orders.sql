{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'fact']
    )
}}

WITH order_metrics AS (
    -- Precalcula todas as métricas baseadas em order_details em uma única passagem
    SELECT
        order_id,
        COUNT(DISTINCT product_id) as total_items,
        SUM(quantity) as total_quantity,
        SUM(unit_price * quantity) as gross_amount,
        SUM(unit_price * quantity * (1 - discount)) as net_amount,
        SUM(unit_price * quantity * discount) as total_discount
    FROM {{ ref('stg_order_details') }}
    GROUP BY order_id
)

SELECT
    -- Dimensões principais primeiro (melhor para índices implícitos)
    o.order_id,
    o.customer_id,
    o.employee_id,
    o.order_date,
    -- Métricas calculadas
    COALESCE(om.total_items, 0) as total_items,
    COALESCE(om.total_quantity, 0) as total_quantity,
    COALESCE(om.gross_amount, 0) as gross_amount,
    COALESCE(om.net_amount, 0) as net_amount,
    COALESCE(om.total_discount, 0) as total_discount,
    -- Informações de entrega
    o.required_date,
    o.shipped_date,
    o.shipper_id,
    o.freight,
    CASE 
        WHEN o.shipped_date IS NULL THEN 'Not Shipped'
        WHEN o.shipped_date > o.required_date THEN 'Late'
        ELSE 'On Time'
    END as delivery_status,
    DATEDIFF('day', o.order_date, COALESCE(o.shipped_date, CURRENT_DATE)) as days_to_ship,
    -- Informações de entrega
    o.ship_name,
    o.ship_address,
    o.ship_city,
    o.ship_region,
    o.ship_postal_code,
    o.ship_country
FROM {{ ref('stg_orders') }} o
LEFT JOIN order_metrics om ON o.order_id = om.order_id