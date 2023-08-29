CREATE VIEW dpfa_seats_v1
AS
WITH sgl_hist_flight -- subquery to pull one flight (TOP 1) given specified conditions in WHERE clause
AS (
    SELECT *
    FROM navitaire.rez_InventoryLeg il
    WHERE DepartureDate BETWEEN GETDATE() AND GETDATE() + 365
        AND il.[Status] <> 2 -- signifies that flight isn't cancelled
        AND il.Lid > 0 -- Lid is max number Pax on a flight, removing any Test Flights where this is 0 instead of 189
        AND il.CarrierCode = 'FR'
    )
    , specific_flight_inventory_leg_id -- pulling info on Pax on flight 
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
    JOIN sgl_hist_flight shf -- joining by InventoryLegID to flight returned in sgl_hist_flight
        ON shf.InventoryLegID = pjl.InventoryLegID
    )
    , all_passengers
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
    JOIN specific_flight_inventory_leg_id fil
        ON pjl.InventoryLegID = fil.InventoryLegID
            AND pjl.PassengerID = fil.PassengerID
    JOIN navitaire.rez_BookingPassenger bp
        ON pjl.PassengerID = bp.PassengerID
    WHERE pjl.Deleted = 0
    )
    , flight_prebooked_passengers
AS (
    SELECT ap.FirstName
        , ap.LastName
        , ap.PaxType
        , ap.DepartureStation
        , ap.ArrivalStation
        , ap.FlightNumber
        , ap.CreatedUTC
        , ap.BookingDate
        , ap.Booking_yr
        , ap.Booking_Month
        , ap.DepartureDate
        , ap.BookingID
        , ap.InventoryLegID
        , ap.PassengerID
        , pf.FeeCode -- this will determine if the Seat 
        , pf.FeeType
        , pfc.ChargeCode
        , pfc.CurrencyCode
        , pfc.ForeignCurrencyCode
        , pfc.ChargeAmount
        , ap.UnitDesignator
        , left(ap.UnitDesignator, 2) AS Seat_Row
        , right(ap.UnitDesignator, 1) AS Seat_Column
    FROM all_passengers ap
    LEFT JOIN navitaire.rez_PassengerFee pf --joining to determine if the Seat was paid for or not
        ON ap.InventoryLegID = pf.InventoryLegID
            AND ap.PassengerID = pf.PassengerID
            AND pf.FeeCode IN ('SEAT', 'SETH', 'SETL', 'STUP', 'SETA', 'SRTL', 'REGU', 'PLUS', 'FAMI', 'SURE', 'SERV') -- all Seat related fee codes
    LEFT JOIN navitaire.rez_PassengerFeeCharge pfc -- joining to return price paid (price paid not actually returned in final data set)
        ON pf.PassengerID = pfc.PassengerID
            AND pf.FeeNumber = pfc.FeeNumber
            AND ABS(pfc.ChargeAmount) > 0 -- ABS turns negative to their absolute value, seat costs often listed as negative value in pfc table
            AND pfc.ChargeCode IN ('SEAT', 'SETH', 'SETL', 'SETA', 'STUP', 'SRTL', 'REGU', 'PLUS', 'FAMI', 'SURE', 'SERV')
    WHERE pfc.Deleted = 0
    )
    , distinct_pax_seats
AS (
    SELECT fpp.FirstName
        , fpp.LastName
        , fpp.PaxType
        , fpp.DepartureStation
        , fpp.ArrivalStation
        , fpp.FlightNumber
        , fpp.CreatedUTC
        , fpp.BookingDate
        , fpp.Booking_yr
        , fpp.Booking_Month
        , fpp.DepartureDate
        , fpp.BookingID
        , fpp.InventoryLegID
        , fpp.PassengerID
        , fpp.FeeCode
        , fpp.FeeType
        , fpp.ChargeCode
        , fpp.CurrencyCode
        , fpp.ChargeAmount
        , CASE 
            WHEN (
                    ChargeAmount IS NULL
                    OR UnitDesignator = ''
                    )
                THEN 0
            ELSE 1
            END AS Seat_Occupied_YN -- splitting out Seats paid for and not paid for
        , fpp.UnitDesignator
        , fpp.Seat_Row
        , fpp.Seat_Column
    FROM flight_prebooked_passengers fpp
    GROUP BY fpp.FirstName
        , fpp.LastName
        , fpp.PaxType
        , fpp.DepartureStation
        , fpp.ArrivalStation
        , fpp.FlightNumber
        , fpp.CreatedUTC
        , fpp.BookingDate
        , fpp.Booking_yr
        , fpp.Booking_Month
        , fpp.DepartureDate
        , fpp.BookingID
        , fpp.InventoryLegID
        , fpp.PassengerID
        , fpp.FeeCode
        , fpp.FeeType
        , fpp.ChargeCode
        , fpp.CurrencyCode
        , fpp.ChargeAmount
        , CASE 
            WHEN (
                    ChargeAmount IS NULL
                    OR UnitDesignator = ''
                    )
                THEN 0
            ELSE 1
            END
        , fpp.UnitDesignator
        , fpp.Seat_Row
        , fpp.Seat_Column
    )
    , flight_level_details
AS (
    SELECT q.*
    FROM (
        SELECT FirstName
            , LastName
            , PaxType
            , CONCAT (
                DepartureStation
                , ArrivalStation
                ) AS Route
            , DepartureStation
            , ArrivalStation
            , FlightNumber
            , dps.CreatedUTC
            , BookingDate
            , Booking_yr
            , Booking_Month
            , DepartureDate
            , BookingID
            , InventoryLegID
            , PassengerID
            , row_number() OVER (
                PARTITION BY InventoryLegID
                , PassengerID ORDER BY InventoryLegID
                    , PassengerID
                    , ABS(dps.ChargeAmount) DESC
                ) AS passenger_rn
            , dps.FeeCode
            , dps.FeeType
            , dps.CurrencyCode
            , ABS(dps.ChargeAmount) AS ChargeAmount
            , CASE 
                WHEN dps.PaxType = 'CHD'
                    THEN 1
                ELSE Seat_Occupied_YN
                END AS Seat_Occupied_YN
            , UnitDesignator
            , Seat_Row
            , Seat_Column
            , CASE 
                WHEN PaxType <> 'CHD'
                    THEN COALESCE(f.Name, 'NOT Prebooked')
                ELSE COALESCE(f.Name, 'Child - Free')
                END AS Seat_Booking_Type
            , CASE 
                WHEN dps.FeeCode IN ('SEAT', 'SETL', 'SETH')
                    THEN 1
                ELSE 0
                END AS Prebooked_Seat_standalone
        -- , CASE
        --     WHEN (dps.FeeCode = 'SERV'
        --     AND PaxType IN ('ADT', 'TEEN'))
        --         THEN 0
        --     ELSE 1
        --     END AS Prebooked_Seat
        FROM distinct_pax_seats dps
        LEFT JOIN navitaire.rez_Fee f -- joining this table to get names associated with FeeCodes
            ON dps.FeeCode = f.FeeCode
        ) q
    WHERE q.passenger_rn = 1
    )
    , label_seats
AS (
    SELECT ffld.*
        , CASE 
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
    FROM flight_level_details AS ffld
    )
    , count_seats_per_group
AS (
    SELECT ls.*
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 6
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 51
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 60
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 12
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 60
            ELSE 0
            END AS number_of_seats_per_group
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_window_seats
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_middle_seats
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_aisle_seats
    FROM label_seats AS ls
    )
    , running_seats_sold
AS (
    SELECT t.*
    FROM (
        SELECT csg.InventoryLegID
            , SUM(csg.Seat_Occupied_YN) OVER (
                PARTITION BY csg.InventoryLegID ORDER BY csg.InventoryLegID
                    , csg.CreatedUTC
                ) AS RunningSeatOccupied
            , SUM(csg.Prebooked_Seat_standalone) OVER (
                PARTITION BY csg.InventoryLegID ORDER BY csg.InventoryLegID
                    , csg.CreatedUTC
                ) AS RunningStandAloneSeatPrebooked
            , row_number() OVER (
                PARTITION BY InventoryLegID ORDER BY InventoryLegID
                    , csg.CreatedUTC DESC
                ) AS booking_date_rank
        FROM count_seats_per_group csg
        ) t
    WHERE booking_date_rank = 1
    )
    , seat_sold_added
AS (
    SELECT csg.*
        , aa.num_seats_occupied_per_group
    FROM (
        SELECT csg.InventoryLegID
            , csg.Model_Seat_Grouping
            , sum(Seat_Occupied_YN) AS num_seats_occupied_per_group
        FROM count_seats_per_group csg
        GROUP BY csg.InventoryLegID
            , csg.Model_Seat_Grouping
        ) aa
    JOIN count_seats_per_group csg
        ON csg.InventoryLegID = aa.InventoryLegID
            AND csg.Model_Seat_Grouping = aa.Model_Seat_Grouping
    )
    , seat_sales_unit_breakdown
AS (
    SELECT ssa.*
        , bb.window_seats_occupied
        , bb.middle_seats_occupied
        , bb.aisle_seats_occupied
        , SUM(Seat_Occupied_YN) OVER (
            PARTITION BY ssa.InventoryLegID
            , ssa.Model_Seat_Grouping
            , ssa.BookingDate ORDER BY ssa.InventoryLegID
                , ssa.Model_Seat_Grouping
                , ssa.BookingDate
            ) AS SeatUnitsOccupied
        , SUM(Prebooked_Seat_standalone) OVER (
            PARTITION BY ssa.InventoryLegID
            , ssa.Model_Seat_Grouping
            , ssa.BookingDate ORDER BY ssa.InventoryLegID
                , ssa.Model_Seat_Grouping
                , ssa.BookingDate
            ) AS StandAloneSeatUnitsPrebooked
        , row_number() OVER (
            PARTITION BY ssa.InventoryLegID
            , ssa.Model_Seat_Grouping ORDER BY ssa.InventoryLegID
                , ssa.CreatedUTC DESC
            ) AS booking_rank_per_group
    FROM (
        SELECT ssa.InventoryLegID
            , Model_Seat_Grouping
            , sum(CASE 
                    WHEN seat_column IN ('A', 'F')
                        THEN Seat_Occupied_YN
                    END) AS window_seats_occupied
            , sum(CASE 
                    WHEN seat_column IN ('B', 'E')
                        THEN Seat_Occupied_YN
                    END) AS middle_seats_occupied
            , sum(CASE 
                    WHEN seat_column IN ('C', 'D')
                        THEN Seat_Occupied_YN
                    END) AS aisle_seats_occupied
        FROM seat_sold_added ssa
        GROUP BY ssa.InventoryLegID
            , ssa.Model_Seat_Grouping
        ) bb
    JOIN seat_sold_added ssa
        ON ssa.InventoryLegID = bb.InventoryLegID
            AND ssa.Model_Seat_Grouping = bb.Model_Seat_Grouping
    )
    , final_seats_details
AS (
    SELECT sub.InventoryLegID
        , rss.RunningSeatOccupied
        , rss.RunningStandAloneSeatPrebooked
        , sub.Model_Seat_Grouping
        , sub.SeatUnitsOccupied
        , sub.StandAloneSeatUnitsPrebooked
        , sub.number_of_seats_per_group
        , sub.total_window_seats
        , sub.total_middle_seats
        , sub.total_aisle_seats
        , sub.num_seats_occupied_per_group
        , sub.window_seats_occupied
        , sub.middle_seats_occupied
        , sub.aisle_seats_occupied
    FROM seat_sales_unit_breakdown sub
    JOIN running_seats_sold rss
        ON sub.InventoryLegID = rss.InventoryLegID
    WHERE sub.booking_rank_per_group = 1
    )
    , flight_unit_details
AS (
    SELECT p.InventoryLegSK
        , p.InventoryLegNK
        , p.Route
        , p.DepartureAirport
        , p.ArrivalAirport
        , p.Region
        , p.RouteGroup
        , p.DepartureDateTimeUTC
        , p.DepartureDateTimeLocal
        , p.FlightCapacity
        , p.FlightTimeCategory
        , DATEDIFF(dd, GETDATE(), CONVERT(DATETIME, p.DepartureDateTimeUTC)) AS NDO
        , p.RunningFlightUnitsSold
        , p.NDO_rank
    FROM (
        SELECT *
            , SUM(FlightUnitsSold) OVER (
                PARTITION BY InventoryLegSK ORDER BY NDO DESC
                ) AS RunningFlightUnitsSold
            , row_number() OVER (
                PARTITION BY InventoryLegSK ORDER BY InventoryLegSK
                    , NDO ASC
                ) AS NDO_rank
        FROM (
            SELECT fr.BookingSK
                , il.InventoryLegSK
                , il.InventoryLegNK
                , il.Route
                , il.DepartureDateTimeUTC
                , il.DepartureDateTimeLocal
                , il.RouteGroup
                , il.DepartureAirport
                , il.ArrivalAirport
                , il.CarrierCode
                , il.FlightNumber
                , il.FlightTimeCategory
                , TRIM(il.RouteSubgroup) AS Region
                , DATEDIFF(dd, CONVERT(DATETIME, CONVERT(VARCHAR(8), fr.DateSK)), CONVERT(DATETIME, CONVERT(VARCHAR(8), fr.DepartureDateSK))) AS NDO
                , fr.DateSK AS PurchaseDateSK
                , fr.DepartureDateSK
                , il.DepartureCountry
                , il.ArrivalCountry
                , il.FlightCapacity
                , SUM(CASE 
                        WHEN ds.ServiceCategory IN ('Flight', 'Business Plus', 'Leisure Plus')
                            AND ds.ServiceClass NOT IN ('X', 'Z')
                            THEN fr.TotalFeeUnits
                        ELSE 0
                        END) AS FlightUnitsSold
                , SUM(CASE 
                        WHEN ds.ServiceCategory IN ('Flight', 'Business Plus', 'Leisure Plus')
                            AND ds.ServiceClass NOT IN ('X', 'Z')
                            THEN fr.TotalChargesEUR
                        ELSE 0
                        END) AS FlightChargesEUR
            FROM revenue_rpt.DimInventoryLeg il
            JOIN revenue_rpt.FactRevenue fr -- was originally left join
                ON il.InventoryLegSK = fr.InventoryLegSK
            JOIN revenue_rpt.DimService ds -- was originally left join
                ON fr.ServiceSK = ds.ServiceSK
                    AND ds.ServiceCategory IN ('Flight', 'Business Plus', 'Leisure Plus', 'Leisure Plus SSR', 'Family Plus SSR', 'Business Plus SSR', 'Regular Plus SSR', 'Seats', 'SSR Fees')
            WHERE il.DepartureDateTimeUTC >= GETDATE()
                AND il.DepartureDateTimeUTC < GETDATE() + 365
                AND il.InventoryLegStatus <> 'Cancelled'
                AND CarrierCode = 'FR'
            GROUP BY il.Route
                , il.DepartureDateTimeUTC
                , il.DepartureDateTimeLocal
                , il.RouteGroup
                , TRIM(il.RouteSubgroup)
                , fr.NumberOfDaySK
                , fr.DateSK
                , il.DepartureAirport
                , il.ArrivalAirport
                , il.CarrierCode
                , il.FlightNumber
                , il.FlightTimeCategory
                , fr.DepartureDateSK
                , il.DepartureCountry
                , il.ArrivalCountry
                , il.FlightCapacity
                , il.InventoryLegSK
                , il.InventoryLegNK
                , fr.BookingSK
            ) a
        ) p
    WHERE NDO_rank = 1
    )
    , test_final
AS (
    SELECT fud.*
        , fsd.*
    FROM flight_unit_details fud
    JOIN final_seats_details fsd
        ON fud.InventoryLegNK = fsd.InventoryLegID
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
    SELECT l.*
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 6
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 51
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 60
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 12
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 60
            ELSE 0
            END AS number_of_seats_per_group
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_window_seats
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_middle_seats
        , CASE 
            WHEN Model_Seat_Grouping = 'Alpha'
                THEN 2
            WHEN Model_Seat_Grouping = 'Beta'
                THEN 17
            WHEN Model_Seat_Grouping = 'Gamma'
                THEN 20
            WHEN Model_Seat_Grouping = 'Delta'
                THEN 4
            WHEN Model_Seat_Grouping = 'Epsilon'
                THEN 20
            ELSE 0
            END AS total_aisle_seats
    FROM (
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
        ) l
    )
    , All_Flights_All_Seat_Groups
AS (
    -- CROSS JOINING the distinct InventoryLegNKs to the distinct Model_Seat_Groupins, i.e. returning every InventoryLegNK with every Model_Seat_Grouping, 6 rows per flight 
    SELECT DISTINCT tf.InventoryLegNK
        , pq.*
    FROM test_final tf
    CROSS JOIN (
        SELECT DISTINCT Model_Seat_Grouping
            , number_of_seats_per_group
            , total_window_seats
            , total_middle_seats
            , total_aisle_seats
        FROM Distinct_New_Model_Groups
        ) pq
    )
    , Final_Data_Set
    -- Returning all data. Still need to replace NULLS for most columns, i.e. the columns where Model_Seat_Grouping seats sold is 0
AS (
    SELECT af.InventoryLegNK
        , tf.InventoryLegSK
        , tf.Route
        , tf.RouteGroup
        , tf.DepartureAirport
        , tf.ArrivalAirport
        , tf.Region
        , tf.DepartureDateTimeUTC
        , tf.DepartureDateTimeLocal
        , tf.FlightCapacity
        , tf.FlightTimeCategory
        , tf.NDO
        , tf.RunningFlightUnitsSold
        , tf.RunningSeatOccupied
        , tf.RunningStandAloneSeatPrebooked
        , tf.InventoryLegID
        , af.Model_Seat_Grouping
        , tf.SeatUnitsOccupied
        , tf.StandAloneSeatUnitsPrebooked
        , af.number_of_seats_per_group
        , af.total_window_seats
        , af.total_middle_seats
        , af.total_aisle_seats
        , tf.num_seats_occupied_per_group
        , tf.window_seats_occupied
        , tf.middle_seats_occupied
        , tf.aisle_seats_occupied
    FROM All_Flights_All_Seat_Groups af
    LEFT JOIN test_final tf
        ON af.InventoryLegNK = tf.InventoryLegNK
            AND af.Model_Seat_Grouping = tf.Model_Seat_Grouping
    )
    , Distinct_Non_Null_Rows
AS (
    -- return flight level data, this subquery should return one row per InventoryLegNK
    SELECT DISTINCT tf.InventoryLegNK
        , tf.InventoryLegSK
        , tf.Route
        , tf.RouteGroup
        , tf.DepartureAirport
        , tf.ArrivalAirport
        , tf.Region
        , tf.DepartureDateTimeUTC
        , tf.DepartureDateTimeLocal
        , tf.FlightTimeCategory
        , tf.FlightCapacity
        , tf.NDO
        , tf.RunningFlightUnitsSold
        , tf.RunningSeatOccupied
        , tf.RunningStandAloneSeatPrebooked
        , tf.NDO_rank
        , tf.InventoryLegID
    FROM test_final tf
    )
    , Replace_Nulls
AS (
    SELECT DISTINCT fds.InventoryLegNK
        , dnnr.InventoryLegSK
        , dnnr.Route
        , dnnr.RouteGroup
        , dnnr.DepartureAirport
        , dnnr.ArrivalAirport
        , dnnr.Region
        , dnnr.DepartureDateTimeUTC
        , dnnr.DepartureDateTimeLocal
        , dnnr.NDO
        , dnnr.FlightTimeCategory
        , dnnr.FlightCapacity
        , dnnr.RunningFlightUnitsSold
        , dnnr.RunningSeatOccupied
        , dnnr.RunningStandAloneSeatPrebooked
        , fds.Model_Seat_Grouping
        , COALESCE(fds.SeatUnitsOccupied, 0) AS SeatUnitsOccupied
        , COALESCE(fds.StandAloneSeatUnitsPrebooked, 0) AS StandAloneSeatUnitsPrebooked
        , fds.number_of_seats_per_group AS seats_per_group_total
        , fds.total_window_seats AS window_seats_total
        , fds.total_middle_seats AS middle_seats_total
        , fds.total_aisle_seats AS aisle_seats_total
        , COALESCE(fds.num_seats_occupied_per_group, 0) AS seats_occupied_per_group_total
        , COALESCE(fds.window_seats_occupied, 0) AS window_seats_occupied
        , COALESCE(fds.middle_seats_occupied, 0) AS middle_seats_occupied
        , COALESCE(fds.aisle_seats_occupied, 0) AS aisle_seats_occupied
    FROM Final_Data_Set fds
    JOIN Distinct_Non_Null_Rows dnnr
        ON fds.InventoryLegNK = dnnr.InventoryLegNK
    )
    , future_flights_unique_daily_routes
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
SELECT rn.*
FROM Replace_Nulls rn
JOIN future_flights_unique_daily_routes ffud
    ON rn.Route = ffud.route
GO
