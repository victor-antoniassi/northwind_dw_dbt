{{
    config(
        materialized='table',
        tags=['staging', 'customers']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'customers') }}
),

cleaned AS (
    SELECT
        CAST(customer_id AS VARCHAR) as customer_id,
        CAST(company_name AS VARCHAR) as company_name,
        CAST(contact_name AS VARCHAR) as contact_name,
        CAST(contact_title AS VARCHAR) as contact_title,
        CAST(address AS VARCHAR) as address,
        CAST(city AS VARCHAR) as city,
        CAST(region AS VARCHAR) as region,
        CAST(postal_code AS VARCHAR) as postal_code,
        CAST(country AS VARCHAR) as country,
        CAST(phone AS VARCHAR) as phone,
        CAST(fax AS VARCHAR) as fax
    FROM source
)

SELECT * FROM cleaned