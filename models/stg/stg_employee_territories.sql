{{
    config(
        materialized='table',
        tags=['staging', 'employees', 'geography']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'employee_territories') }}
),

cleaned AS (
    SELECT
        CAST(employee_id AS INTEGER) as employee_id,
        CAST(territory_id AS VARCHAR) as territory_id
    FROM source
)

SELECT * FROM cleaned