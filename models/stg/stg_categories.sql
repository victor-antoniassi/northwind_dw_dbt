{{
    config(
        materialized='table',
        tags=['staging', 'products']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'categories') }}
),

cleaned AS (
    SELECT
        CAST(category_id AS INTEGER) as category_id,
        CAST(category_name AS VARCHAR) as category_name,
        CAST(description AS VARCHAR) as description
    FROM source
)

SELECT * FROM cleaned