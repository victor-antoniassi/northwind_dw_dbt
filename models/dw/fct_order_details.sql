{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'fact']
    )
}}

WITH order_info AS (
    -- Pré-seleciona apenas as colunas necessárias das orders
    SELECT 
        order_id,
        customer_id,
        employee_id,
        order_date,
        shipper_id
    FROM {{ ref('stg_orders') }}
),

product_info AS (
    -- Pré-seleciona apenas as colunas necessárias dos produtos
    SELECT
        product_id,
        unit_price as list_price,
        category_id,
        supplier_id
    FROM {{ ref('stg_products') }}
)

SELECT
    -- Chaves primeiro (melhor para índices implícitos)
    od.order_id,
    od.product_id,
    oi.customer_id,
    oi.employee_id,
    -- Datas
    oi.order_date,
    -- Informações do item
    oi.shipper_id,
    od.unit_price as sold_price,
    pi.list_price,
    od.quantity,
    od.discount,
    -- Métricas calculadas
    od.unit_price * od.quantity as gross_amount,
    od.unit_price * od.quantity * (1 - od.discount) as net_amount,
    od.unit_price * od.quantity * od.discount as discount_amount,
    -- Flags analíticas
    CASE 
        WHEN od.unit_price > pi.list_price THEN 'Price Increase'
        WHEN od.unit_price < pi.list_price THEN 'Price Decrease'
        ELSE 'No Change'
    END as price_change_flag,
    -- Dimensões relacionadas
    pi.category_id,
    pi.supplier_id
FROM {{ ref('stg_order_details') }} od
-- Joins apenas com as colunas necessárias já pré-selecionadas
JOIN order_info oi ON od.order_id = oi.order_id
LEFT JOIN product_info pi ON od.product_id = pi.product_id