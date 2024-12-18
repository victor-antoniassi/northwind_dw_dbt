{{
    config(
        materialized='table',
        tags=['staging', 'employees']
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'employees') }}
),

cleaned AS (
    SELECT
        CAST(employee_id AS INTEGER) as employee_id,
        CAST(last_name AS VARCHAR) as last_name,
        CAST(first_name AS VARCHAR) as first_name,
        CAST(title AS VARCHAR) as title,
        CAST(title_of_courtesy AS VARCHAR) as title_of_courtesy,
        CAST(birth_date AS DATE) as birth_date,
        CAST(hire_date AS DATE) as hire_date,
        CAST(address AS VARCHAR) as address,
        CAST(city AS VARCHAR) as city,
        CAST(region AS VARCHAR) as region,
        CAST(postal_code AS VARCHAR) as postal_code,
        CAST(country AS VARCHAR) as country,
        CAST(home_phone AS VARCHAR) as home_phone,
        CAST(extension AS VARCHAR) as extension,
        CAST(reports_to AS INTEGER) as reports_to
    FROM source
)

SELECT * FROM cleaned