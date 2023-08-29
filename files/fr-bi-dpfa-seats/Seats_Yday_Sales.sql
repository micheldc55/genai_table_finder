CREATE VIEW DPFA_Yesterday_SeatUnitsSold
AS
WITH Sgl_Hist_Flight -- subquery to pull one flight (TOP 1) given specified conditions in WHERE clause
AS (
    SELECT il.InventoryLegID
        , il.DepartureDate
        , il.DepartureStation
        , il.ArrivalStation
        , il.FlightNumber
    FROM navitaire.rez_InventoryLeg il
    WHERE DepartureDate BETWEEN GETDATE() AND GETDATE() + 365
        AND il.[Status] <> 2 -- signifies that flight isn't cancelled
        AND il.Lid > 0 -- Lid is max number Pax on a flight, removing any Test Flights where this is 0 instead of 189
        AND il.CarrierCode = 'FR'
    )
    , Specific_Flight_Inventory_Leg_ID -- pulling info on Pax on flight 
AS (
    SELECT bp.FirstName
        , bp.LastName
        , bp.PaxType
        , pjl.PassengerID
        , pjl.InventoryLegID
        , shf.DepartureDate
        , shf.DepartureStation
        , shf.ArrivalStation
        , shf.FlightNumber
    FROM navitaire.rez_PassengerJourneyLeg pjl
    JOIN navitaire.rez_BookingPassenger bp
        ON pjl.PassengerID = bp.PassengerID
    JOIN Sgl_Hist_Flight shf -- joining by InventoryLegID to flight returned in sgl_hist_flight
        ON shf.InventoryLegID = pjl.InventoryLegID
    )
    , All_Passengers
AS (
    SELECT bp.FirstName
        , bp.LastName
        , bp.PaxType -- if the Pax is ADULT/TEEN/CHILD
        , fil.DepartureDate
        , pjl.CreatedUTC
        , CAST(pjl.CreatedUTC AS DATE) AS BookingDate
        , DATEPART(MONTH, pjl.CreatedUTC) AS Booking_Month
        , DATEPART(YEAR, pjl.CreatedUTC) AS Booking_yr
        , fil.DepartureStation
        , fil.ArrivalStation
        , fil.FlightNumber
        , fil.InventoryLegID
        , pjl.PassengerID
        , bp.BookingID
        , pjl.UnitDesignator -- Seat Row & Col for each passenger (e.g.18D) whether the Seat was purchased or not
        , pjl.Deleted
    FROM navitaire.rez_PassengerJourneyLeg pjl -- joining this table to return the Unit Designator
    JOIN Specific_Flight_Inventory_Leg_ID fil
        ON pjl.InventoryLegID = fil.InventoryLegID
            AND pjl.PassengerID = fil.PassengerID
    JOIN navitaire.rez_BookingPassenger bp
        ON pjl.PassengerID = bp.PassengerID
    WHERE pjl.Deleted = 0
    )
    , Flight_Prebooked_Passengers
AS (
    SELECT DISTINCT ap.FirstName
        , ap.LastName
        , ap.PaxType
        , ap.DepartureStation
        , ap.ArrivalStation
        , ap.FlightNumber
        , ap.CreatedUTC
        , ap.BookingID
        , db.BookingNK
        , db.BookingSK
        , ap.BookingDate
        , ap.Booking_yr
        , ap.Booking_Month
        , ap.DepartureDate
        , ap.InventoryLegID
        , ap.PassengerID
        , fr.ChargeLifeStageSK
        , pf.FeeCode -- this will determine if the Seat 
        , ap.UnitDesignator
        , left(ap.UnitDesignator, 2) AS Seat_Row
        , right(ap.UnitDesignator, 1) AS Seat_Column
    FROM All_Passengers ap
    JOIN revenue_rpt.DimBooking db
        ON ap.BookingID = db.BookingNK
    JOIN revenue_rpt.FactRevenue fr
        ON db.BookingSK = fr.BookingSK
            AND fr.ChargeLifeStageSK = 1
    LEFT JOIN navitaire.rez_PassengerFee pf --joining to determine if the Seat was paid for or not
        ON ap.InventoryLegID = pf.InventoryLegID
            AND ap.PassengerID = pf.PassengerID
            AND pf.FeeCode IN ('SEAT') -- all Seat related fee codes
    LEFT JOIN navitaire.rez_PassengerFeeCharge pfc -- joining to return price paid (price paid not actually returned in final data set)
        ON pf.PassengerID = pfc.PassengerID
            AND pf.FeeNumber = pfc.FeeNumber
            AND ABS(pfc.ChargeAmount) > 0 -- ABS turns negative to their absolute value, seat costs often listed as negative value in pfc table
            AND pfc.ChargeCode IN ('SEAT')
    WHERE pfc.Deleted = 0
        AND BookingDate = CASE 
            WHEN DATENAME(WEEKDAY, GETDATE()) = 'Monday'
                THEN CONVERT(DATE, GETDATE() - 3)
            ELSE CONVERT(DATE, GETDATE() - 1)
            END
    )
    , Label_Seats
AS (
    SELECT ffld.InventoryLegID
        , CASE 
            WHEN sa.SeatRowNumber = 1
                THEN 'Alpha'
            WHEN (
                    sa.SeatRowNumber = 2
                    AND sa.SeatRowLetter IN ('D', 'E', 'F')
                    )
                THEN 'Alpha'
            WHEN (
                    sa.SeatRowNumber = '02'
                    AND sa.SeatRowLetter IN ('A', 'B', 'C')
                    )
                THEN 'Beta'
            WHEN sa.SeatRowNumber IN (03, 04, 05, 06, 07, 08, 09, 10)
                THEN 'Beta'
            WHEN sa.SeatRowNumber IN (11, 12, 14, 15, 18, 19, 20, 31, 32, 33)
                THEN 'Gamma'
            WHEN sa.SeatRowNumber IN (16, 17)
                THEN 'Delta'
            WHEN sa.SeatRowNumber IN (21, 22, 23, 24, 25, 26, 27, 28, 29, 30)
                THEN 'Epsilon'
            ELSE 'NO LABEL'
            END AS Model_Seat_Grouping
    FROM Flight_Prebooked_Passengers AS ffld
    JOIN (
        SELECT DISTINCT sa.Seat
            , sa.SeatRowNumber
            , sa.SeatRowLetter
        FROM revenue_rpt.SeatsAncillaries sa
        ) sa
        ON ffld.UnitDesignator = sa.Seat
    )
    , Yesterday_Standalone_Seats
AS (
    SELECT ls.InventoryLegID
        , ls.Model_Seat_Grouping
        , count(*) AS StandAloneSeatUnitsPrebooked
    FROM Label_Seats AS ls
    GROUP BY ls.InventoryLegID
        , ls.Model_Seat_Grouping
    )
    , Distinct_Seats
AS (
    -- returns all 189 seats
    SELECT DISTINCT seat
        , seatrownumber AS Seat_Row
        , seatrowletter AS Seat_Column
    FROM revenue_rpt.SeatsAncillaries
    WHERE seatrownumber <= 33
        AND seat NOT IN ('01D', '01E', '01F')
        AND SeatRowNumber != 13
    )
    , Distinct_New_Model_Groups
    -- returns the six distinct Model_Seat_Groupings, and seats available
AS (
    SELECT DISTINCT CASE 
            WHEN Seat_Row = 1
                THEN 'Alpha'
            WHEN (
                    Seat_Row = 2
                    AND Seat_Column IN ('D', 'E', 'F')
                    )
                THEN 'Alpha'
            WHEN (
                    Seat_Row = 2
                    AND Seat_Column IN ('A', 'B', 'C')
                    )
                THEN 'Beta'
            WHEN Seat_Row IN (3, 4, 5, 6, 7, 8, 9, 10)
                THEN 'Beta'
            WHEN Seat_Row IN (11, 12, 14, 15, 18, 19, 20, 31, 32, 33)
                THEN 'Gamma'
            WHEN Seat_Row IN (16, 17)
                THEN 'Delta'
            WHEN Seat_Row IN (21, 22, 23, 24, 25, 26, 27, 28, 29, 30)
                THEN 'Epsilon'
            ELSE 'NO LABEL'
            END AS Model_Seat_Grouping
    FROM Distinct_Seats
    )
    , All_Flights_All_Seat_Groups
AS (
    -- CROSS JOINING the distinct InventoryLegNKs to the distinct Model_Seat_Groupins, i.e. returning every InventoryLegNK with every Model_Seat_Grouping, 6 rows per flight 
    SELECT DISTINCT fpp.InventoryLegID
        , pq.Model_Seat_Grouping
    FROM Sgl_Hist_Flight fpp
    CROSS JOIN (
        SELECT DISTINCT Model_Seat_Grouping
        FROM Distinct_New_Model_Groups
        ) pq
    )
    , Future_Flights_Unique_Daily_Routes
AS (
    SELECT q.route
        , max_daily_flights
    FROM (
        SELECT p.route
            , max(Num_Flights) AS max_daily_flights
        FROM (
            SELECT ff.DepartureDate
                , ff.Route
                , count(DISTINCT (InventoryLegID)) AS Num_Flights
            FROM yield.dbo_FutureFlights ff
            JOIN revenue_rpt.DimInventoryLeg il
                ON ff.InventoryLegSK = il.InventoryLegSK
                    AND lower(il.InventoryLegStatus) <> 'cancelled'
                    AND DepartedFlag = 'N'
                    AND DepartureDateTimeUTC > GETDATE()
            GROUP BY ff.DepartureDate
                , ff.Route
            ) p
        GROUP BY p.route
        ) q
    WHERE q.max_daily_flights = 1
    )
SELECT al.InventoryLegID
    , al.Model_Seat_Grouping
    , COALESCE(yss.StandAloneSeatUnitsPrebooked, 0) AS StandAloneSeatUnitsPrebooked
FROM All_Flights_All_Seat_Groups al
LEFT JOIN Yesterday_Standalone_Seats yss
    ON al.InventoryLegID = yss.InventoryLegID
        AND al.Model_Seat_Grouping = yss.Model_Seat_Grouping
JOIN navitaire.rez_InventoryLeg il
    ON al.InventoryLegID = il.InventoryLegID
JOIN Future_Flights_Unique_Daily_Routes fud
    ON CONCAT (
            il.DepartureStation
            , il.ArrivalStation
            ) = fud.Route
-- ORDER BY InventoryLegID
--     , Model_Seat_Grouping
    GO
