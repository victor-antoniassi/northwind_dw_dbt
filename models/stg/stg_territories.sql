{{
    config(
        materialized='table',
        tags=['staging', 'employees', 'geography']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'territories') }}
),

cleaned AS (
    SELECT
        CAST(territory_id AS VARCHAR) as territory_id,
        CAST(territory_description AS VARCHAR) as territory_description,
        CAST(region_id AS INTEGER) as region_id
    FROM source
)

SELECT * FROM cleaned