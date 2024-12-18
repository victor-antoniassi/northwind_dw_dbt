{{
    config(
        materialized='table',
        tags=['staging', 'shipping']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'shippers') }}
),

cleaned AS (
    SELECT
        CAST(shipper_id AS INTEGER) as shipper_id,
        CAST(company_name AS VARCHAR) as company_name,
        CAST(phone AS VARCHAR) as phone
    FROM source
)

SELECT * FROM cleaned