{{
    config(
        materialized='table',
        tags=['staging', 'products']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'products') }}
),

cleaned AS (
    SELECT
        CAST(product_id AS INTEGER) as product_id,
        CAST(product_name AS VARCHAR) as product_name,
        CAST(supplier_id AS INTEGER) as supplier_id,
        CAST(category_id AS INTEGER) as category_id,
        CAST(quantity_per_unit AS VARCHAR) as quantity_per_unit,
        CAST(unit_price AS DECIMAL(10,2)) as unit_price,
        CAST(units_in_stock AS INTEGER) as units_in_stock,
        CAST(units_on_order AS INTEGER) as units_on_order,
        CAST(reorder_level AS INTEGER) as reorder_level,
        CAST(discontinued AS INTEGER) as discontinued
    FROM source
)

SELECT * FROM cleaned