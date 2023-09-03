CREATE OR REPLACE VIEW "dl_target_curves_vw" AS
WITH
    valid_rl_target_curves
    AS
    (
        SELECT
            target_key
    , load_name
    , load_timestamp
    , extreme_lower
    , mid_lower
    , mid_upper
    , extreme_upper
    , expectedlf_rescaled
    , (CASE WHEN (length(load_timestamp) = 11) THEN load_timestamp ELSE substring(load_timestamp, 3) END) valid_load_timestamp
        FROM
            rl_target_curves
    )
,
    periods
    AS
    (
        SELECT
            valid_load_timestamp
    , COALESCE(lag(valid_load_timestamp) OVER (PARTITION BY 1 ORDER BY valid_load_timestamp DESC), '991231_0000') valid_to
        FROM
            (
    SELECT DISTINCT valid_load_timestamp
            FROM valid_rl_target_curves
  )
    )
SELECT
    target_key
  , load_name
  , load_timestamp
  , extreme_lower
  , mid_lower
  , mid_upper
  , extreme_upper
  , expectedlf_rescaled
  , tc.valid_load_timestamp valid_from
  , pr.valid_to valid_to
  , ('991231_0000' = pr
.valid_to) active
FROM
(
  valid_rl_target_curves tc
  INNER JOIN periods pr ON
(pr.valid_load_timestamp = tc.valid_load_timestamp))