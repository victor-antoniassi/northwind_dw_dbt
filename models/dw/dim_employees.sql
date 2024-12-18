{{
    config(
        materialized='table',
        schema='dw',
        tags=['dw', 'dimension']
    )
}}

WITH employee_sales AS (
    -- Precalcula métricas de vendas por funcionário
    SELECT 
        employee_id,
        COUNT(DISTINCT order_id) as total_orders,
        COUNT(DISTINCT customer_id) as total_customers,
        SUM(
            COALESCE(
                (SELECT SUM(unit_price * quantity * (1-discount))
                FROM {{ ref('stg_order_details') }} od 
                WHERE od.order_id = o.order_id), 
            0)
        ) as total_sales_amount
    FROM {{ ref('stg_orders') }} o
    GROUP BY employee_id
),

territory_info AS (
    -- Agrega informações de territórios
    SELECT 
        et.employee_id,
        COUNT(DISTINCT t.territory_id) as total_territories,
        STRING_AGG(DISTINCT t.territory_description, ', ') as territories,
        STRING_AGG(DISTINCT r.region_description, ', ') as regions
    FROM {{ ref('stg_employee_territories') }} et
    LEFT JOIN {{ ref('stg_territories') }} t ON et.territory_id = t.territory_id
    LEFT JOIN {{ ref('stg_region') }} r ON t.region_id = r.region_id
    GROUP BY et.employee_id
)

SELECT
    -- Identificação
    e.employee_id,
    e.first_name || ' ' || e.last_name as employee_name,
    e.title,
    e.title_of_courtesy,
    -- Datas e tempo de serviço
    e.birth_date,
    e.hire_date,
    DATEDIFF('year', e.birth_date, CURRENT_DATE) as age,
    DATEDIFF('year', e.hire_date, CURRENT_DATE) as years_of_service,
    -- Localização
    e.address,
    e.city,
    e.region,
    e.postal_code,
    e.country,
    -- Contato
    e.home_phone,
    e.extension,
    -- Hierarquia
    e.reports_to,
    m.first_name || ' ' || m.last_name as manager_name,
    -- Territórios
    COALESCE(ti.total_territories, 0) as total_territories,
    ti.territories,
    ti.regions,
    -- Métricas de vendas
    COALESCE(es.total_orders, 0) as total_orders,
    COALESCE(es.total_customers, 0) as total_customers,
    COALESCE(es.total_sales_amount, 0) as total_sales_amount,
    CASE 
        WHEN es.total_orders > 0 THEN 
            es.total_sales_amount / es.total_orders 
        ELSE 0 
    END as avg_order_value
FROM {{ ref('stg_employees') }} e
LEFT JOIN {{ ref('stg_employees') }} m ON e.reports_to = m.employee_id
LEFT JOIN territory_info ti ON e.employee_id = ti.employee_id
LEFT JOIN employee_sales es ON e.employee_id = es.employee_id