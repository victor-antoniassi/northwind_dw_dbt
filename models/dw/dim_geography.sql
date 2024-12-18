{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH location_source AS (
    -- Unifica todas as fontes de localização
    SELECT
        city,
        region,
        postal_code,
        country,
        'Customer' as location_type,
        COUNT(*) as customer_count,
        0 as employee_count,
        0 as supplier_count
    FROM {{ ref('stg_customers') }}
    GROUP BY city, region, postal_code, country
    
    UNION ALL
    
    SELECT
        city,
        region,
        postal_code,
        country,
        'Employee' as location_type,
        0 as customer_count,
        COUNT(*) as employee_count,
        0 as supplier_count
    FROM {{ ref('stg_employees') }}
    GROUP BY city, region, postal_code, country
    
    UNION ALL
    
    SELECT
        city,
        region,
        postal_code,
        country,
        'Supplier' as location_type,
        0 as customer_count,
        0 as employee_count,
        COUNT(*) as supplier_count
    FROM {{ ref('stg_suppliers') }}
    GROUP BY city, region, postal_code, country
),

location_metrics AS (
    -- Agrega métricas de vendas por localização
    SELECT 
        ship_city as city,
        ship_region as region,
        ship_postal_code as postal_code,
        ship_country as country,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(freight) as total_freight
    FROM {{ ref('stg_orders') }}
    GROUP BY ship_city, ship_region, ship_postal_code, ship_country
)

SELECT
    -- Chave surrogate
    ROW_NUMBER() OVER (ORDER BY l.country, l.region, l.city) as geography_id,
    -- Localização
    l.city,
    l.region,
    l.postal_code,
    l.country,
    -- Contagens por tipo
    SUM(l.customer_count) as total_customers,
    SUM(l.employee_count) as total_employees,
    SUM(l.supplier_count) as total_suppliers,
    -- Tipos de local
    STRING_AGG(DISTINCT 
        CASE WHEN l.customer_count > 0 THEN 'Customer'
             WHEN l.employee_count > 0 THEN 'Employee'
             WHEN l.supplier_count > 0 THEN 'Supplier'
        END, ', ') as location_types,
    -- Métricas de vendas
    COALESCE(lm.total_orders, 0) as total_orders,
    COALESCE(lm.total_freight, 0) as total_freight
FROM location_source l
LEFT JOIN location_metrics lm ON 
    l.city = lm.city AND 
    COALESCE(l.region, '') = COALESCE(lm.region, '') AND 
    COALESCE(l.postal_code, '') = COALESCE(lm.postal_code, '') AND 
    l.country = lm.country
GROUP BY 
    l.city,
    l.region,
    l.postal_code,
    l.country,
    lm.total_orders,
    lm.total_freight