-- Databricks notebook source
-- MAGIC %md
-- MAGIC ### CSV files | Table names 

-- COMMAND ----------

-- MAGIC %md
-- MAGIC - route_region_info.csv | route_region_info
-- MAGIC - city_code_names.csv | city_names
-- MAGIC - competition_cnt.csv | competition_cnt
-- MAGIC - airport_flight_cnt.csv | airport_flights_count

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Drop tables if exist

-- COMMAND ----------

drop table if exists datascience_dev.networkplanning.route_region_info;
drop table if exists datascience_dev.networkplanning.stg_route_region_info;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Create external table

-- COMMAND ----------

create external table datascience_dev.networkplanning.route_region_info
using csv 
location
'abfss://dbrdevlanding@frbinetraunitycatalog.dfs.core.windows.net/DS/NetworkPlanning/CSVInputs/route_region_info.csv'

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Check columns

-- COMMAND ----------

select * from datascience_dev.networkplanning.route_region_info

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Create a delta table

-- COMMAND ----------

ALTER TABLE datascience_dev.networkplanning.route_region_info
    RENAME TO datascience_dev.networkplanning.stg_route_region_info;

CREATE TABLE datascience_dev.networkplanning.route_region_info
(
    _c0 string
    ,_c1 string
    ,_c2 string
    ,_c3 string
    -- ,_c4 string
    ,LastUpdatedDate timestamp --GENERATED ALWAYS AS (CURRENT_TIMESTAMP())
);

INSERT INTO datascience_dev.networkplanning.route_region_info
(
    _c0 
    ,_c1 
    ,_c2 
    ,_c3
    -- ,_c4
    ,LastUpdatedDate
)
SELECT
    _c0 string
    ,_c1 string
    ,_c2 string
    ,_c3 string
    -- ,_c4 string
    ,CURRENT_TIMESTAMP()
FROM
    datascience_dev.networkplanning.stg_route_region_info;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ### Create a city names dict

-- COMMAND ----------

CREATE OR REPLACE TABLE datascience_dev.networkplanning.city_names_dict
COMMENT 'City names dictionary'

SELECT DISTINCT AirportCode, City 
FROM (
  (
    SELECT DISTINCT
      _c0 AS AirportCode,
      _c2 AS City
    FROM datascience_dev.networkplanning.city_names WHERE _c2 IS NOT NULL
  )
  union 
  (
    SELECT DISTINCT
      _c0 AS AirportCode,
      _c2 AS City
    FROM datascience_dev.networkplanning.city_names WHERE _c2 IS NOT NULL

  )
)


-- COMMAND ----------


