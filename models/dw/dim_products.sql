{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH product_sales AS (
    -- Precalcula métricas de vendas
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(quantity) as total_quantity_sold,
        AVG(unit_price) as avg_selling_price,
        MAX(order_id) as last_order_id
    FROM {{ ref('stg_order_details') }}
    GROUP BY product_id
)

SELECT
    -- Chaves e identificadores
    p.product_id,
    p.product_name,
    p.supplier_id,
    p.category_id,
    -- Informações de produto
    p.quantity_per_unit,
    p.unit_price as current_price,
    COALESCE(ps.avg_selling_price, p.unit_price) as avg_selling_price,
    -- Estoque
    p.units_in_stock,
    p.units_on_order,
    p.reorder_level,
    p.discontinued,
    -- Categoria
    c.category_name,
    c.description as category_description,
    -- Fornecedor
    s.company_name as supplier_name,
    s.country as supplier_country,
    -- Métricas de vendas
    COALESCE(ps.total_orders, 0) as total_orders,
    COALESCE(ps.total_quantity_sold, 0) as total_quantity_sold,
    -- Status calculados
    CASE 
        WHEN p.discontinued = 1 THEN 'Discontinued'
        WHEN p.units_in_stock = 0 AND p.units_on_order = 0 THEN 'Out of Stock'
        WHEN p.units_in_stock <= p.reorder_level THEN 'Low Stock'
        ELSE 'In Stock'
    END as stock_status
FROM {{ ref('stg_products') }} p
LEFT JOIN product_sales ps ON p.product_id = ps.product_id
LEFT JOIN {{ ref('stg_categories') }} c ON p.category_id = c.category_id
LEFT JOIN {{ ref('stg_suppliers') }} s ON p.supplier_id = s.supplier_id