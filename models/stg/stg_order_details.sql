{{
    config(
        materialized='table',
        tags=['staging', 'orders', 'sales']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'order_details') }}
),

cleaned AS (
    SELECT
        CAST(order_id AS INTEGER) as order_id,
        CAST(product_id AS INTEGER) as product_id,
        CAST(unit_price AS DECIMAL(10,2)) as unit_price,
        CAST(quantity AS INTEGER) as quantity,
        CAST(discount AS DECIMAL(4,2)) as discount
    FROM source
)

SELECT * FROM cleaned