 with future_flights as(
  select inventorylegid, departuredate, flightnumber, departurestation, arrivalstation from navitaire_prod.inventoryleg
  where concat(departurestation, arrivalstation) in ($testRoutes)  -- SET ROUTES
    and cast(stdutc as timestamp) > cast(current_timestamp as timestamp)
    and status = 0 -- status 0 is for all flights still going
    ),
 most_recent_scrape as (
    SELECT fpu.flightnumber , cast(fpu.departure AS DATE) AS departure , max(fpu.priceupdated) AS most_recent_scrape
    FROM farefinder_logger_prod.farefinder_price_updates fpu
    WHERE concat(departureairport, arrivalairport) in ($testRoutes) -- SET ROUTES
        AND departure > current_timestamp
    GROUP BY fpu.flightnumber , cast(fpu.departure AS DATE)
    ORDER BY flightnumber , departure
    ) ,
 full_details as (
    SELECT mrs.flightnumber , fpu.departureairport, fpu.arrivalairport, fpu.departure, fpu.priceeur, fpu.priceupdated
    FROM most_recent_scrape mrs
    JOIN farefinder_logger_prod.farefinder_price_updates fpu
        ON mrs.flightnumber = fpu.flightnumber
            AND cast(mrs.departure AS DATE) = cast(fpu.departure AS DATE)
            AND mrs.most_recent_scrape = fpu.priceupdated
    )
SELECT *
FROM (
    SELECT ff.inventorylegid AS InventoryLegID
        , fd.priceeur AS FlightChargesEUR_unit
    FROM full_details fd
    JOIN future_flights ff
        ON fd.departureairport = ff.departurestation
            AND fd.arrivalairport = ff.arrivalstation
            AND substring(fd.flightnumber, 3, 4) = ff.flightnumber
            AND cast(fd.departure AS DATE) = cast(ff.departuredate AS DATE)
    )
ORDER BY InventoryLegID
