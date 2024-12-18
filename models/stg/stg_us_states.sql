{{
    config(
        materialized='table',
        tags=['staging', 'geography']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'us_states') }}
),

cleaned AS (
    SELECT
        CAST(state_id AS VARCHAR) as state_id,
        CAST(state_name AS VARCHAR) as state_name,
        CAST(state_abbr AS VARCHAR) as state_abbr,
        CAST(state_region AS VARCHAR) as state_region
    FROM source
)

SELECT * FROM cleaned