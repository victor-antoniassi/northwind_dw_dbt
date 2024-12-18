{{
    config(
        materialized='table',
        tags=['staging', 'geography']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'region') }}
),

cleaned AS (
    SELECT
        CAST(region_id AS INTEGER) as region_id,
        CAST(region_description AS VARCHAR) as region_description
    FROM source
)

SELECT * FROM cleaned