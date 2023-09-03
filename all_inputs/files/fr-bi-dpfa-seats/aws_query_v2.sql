WITH future_flights
AS (
    SELECT inventorylegid
        , departuredate
        , flightnumber
        , departurestation
        , arrivalstation
    FROM navitaire_prod.inventoryleg
    WHERE cast(stdutc AS TIMESTAMP) > cast(current_timestamp AS TIMESTAMP)
        AND STATUS = 0 -- status 0 is for all flights still going
        AND concat(departurestation, arrivalstation) in ('NAPCRL') -- SET ROUTES
    )
    , most_recent_scrape
AS (
    SELECT fpu.flightnumber
        , cast(fpu.departure AS DATE) AS departure
        , max(fpu.priceupdated) AS most_recent_scrape
    FROM farefinder_logger_prod.farefinder_price_updates fpu
    WHERE departure > current_timestamp
    AND concat(departureairport, arrivalairport) in ('NAPCRL') -- SET ROUTES
    GROUP BY fpu.flightnumber
        , cast(fpu.departure AS DATE)
    ORDER BY flightnumber
        , departure
    )
    , full_details
AS (
    SELECT mrs.flightnumber
        , fpu.departureairport
        , fpu.arrivalairport
        , fpu.departure
        , fpu.priceeur
        , fpu.priceupdated
    FROM most_recent_scrape mrs
    JOIN farefinder_logger_prod.farefinder_price_updates fpu
        ON mrs.flightnumber = fpu.flightnumber
            AND cast(mrs.departure AS DATE) = cast(fpu.departure AS DATE)
            AND mrs.most_recent_scrape = fpu.priceupdated
    )
SELECT DISTINCT a.InventoryLegID AS InventoryLegID
    , max(a.FlightChargesEUR_unit) AS FlightChargesEur_unit
FROM (
    -- adding MAX function to remove the small number of cases with two prices resulting from one particular scrape timestamp
    SELECT ff.inventorylegid AS InventoryLegID
        , fd.priceeur AS FlightChargesEUR_unit
    FROM full_details fd
    JOIN future_flights ff
        ON fd.departureairport = ff.departurestation
            AND fd.arrivalairport = ff.arrivalstation
            AND substring(fd.flightnumber, 3, 4) = ff.flightnumber
            AND cast(fd.departure AS DATE) = cast(ff.departuredate AS DATE)
  WHERE ff.departuredate <= '2021-11-30'
    ) a
WHERE SUBSTR(CAST(InventoryLegID AS VARCHAR(20)), -1) != '4' AND SUBSTR(CAST(InventoryLegID AS VARCHAR(20)), -1) != '3'
GROUP BY a.inventorylegid
ORDER BY a.inventorylegid
