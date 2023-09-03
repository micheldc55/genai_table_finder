DECLARE @startdatesk BIGINT = 20230602,
            @enddatesk   BIGINT = 20230731;
WITH
    sold
    AS
    (
        SELECT
            il.InventoryLegSK
              --,CAST(il.InventoryLegNK AS BIGINT) AS InventoryLegID
              , il.InventoryLegNK AS InventoryLegID
              , fr.BookingSK
              , fr.DateSK
              , bk.BookingDateTimeUTC
                --, FORMAT(il.DepartureDateTimeLocal, 'yyyyMM') DepYYMM,
                , SUM( CASE
                           WHEN ds.ServiceCategory IN ( 'Flight', 'Business Plus', 'Leisure Plus' )
                                --AND ds.ServiceClass NOT IN ( 'X', 'Z' )
                           THEN fr.TotalFeeUnits
                           ELSE 0
                       END
                   )                                        AS Passengers
            -- 20 KG
            , SUM(CASE WHEN ds.ServiceNK = 'BBG1' THEN fr.TotalFeeUnits ELSE 0 END) as [20KGBagUnitsSold]
            , SUM(CASE WHEN ds.ServiceNK = 'BBG1' THEN fr.TotalChargesEUR ELSE 0 END) as [20KGBagChargesEUR]
            -- 10 KG
            , SUM(CASE WHEN ds.ServiceNK = 'CBAG' THEN fr.TotalFeeUnits ELSE 0 END) as [10KGBagUnitsSold]
            , SUM(CASE WHEN ds.ServiceNK = 'CBAG' THEN fr.TotalChargesEUR ELSE 0 END) as [10KGBagChargesEUR]
            -- Priority Boarding
            , SUM(CASE WHEN ds.ServiceNK in ('PS', 'PB', 'PF', 'MPS') THEN fr.TotalFeeUnits ELSE 0 END) as PBUnitsSold
            , SUM(CASE WHEN ds.ServiceNK in ('PS', 'PB', 'PF', 'MPS') THEN fr.TotalChargesEUR ELSE 0 END) as PBChargesEUR
        FROM
            revenue_rpt.FactRevenue          fr
            JOIN revenue_rpt.DimService      ds ON fr.ServiceSK = ds.ServiceSK
            JOIN revenue_rpt.DimChargeLifeStage ls ON fr.ChargeLifeStageSK = ls.ChargeLifeStageSK
            JOIN revenue_rpt.DimInventoryLeg il ON il.InventoryLegSK = fr.InventoryLegSK
            LEFT JOIN revenue_rpt.[DimBooking] bk ON bk.BookingSK = fr.BookingSK
        WHERE
                (ds.ServiceCategory IN ( 'Flight', 'Business Plus', 'Leisure Plus' )
            OR ds.ServiceNK IN ('PS', 'PB', 'PF', 'MPS', 'BBG1','CBAG'))
            AND fr.DateSK
                BETWEEN @startdatesk AND @enddatesk
            AND il.CarrierCode NOT IN ( 'RR' )
            AND ChargeStageGroup = 'Trip'
            AND DepartureCountry != 'Spain'
            AND ArrivalCountry != 'Spain'
        --AND il.InventoryLegSK = 10699647
        GROUP BY
                il.InventoryLegSK
               ,il.InventoryLegNK
               ,fr.BookingSK
               ,fr.DateSK
               ,bk.BookingDateTimeUTC
    ),
    maxbag10kg
    AS
    (
        SELECT a.InventoryLegSK, MAX(a.ModelDate) AS ModelDate, sold.DateSK
        FROM sold
            JOIN [datascience_rpt].[vw_AncDynPricing_CBAGPredictionsSnapshots] a
            ON a.InventoryLegSK = sold.InventoryLegSK
                AND a.[Trip Type] = 'POTENTIAL'
                AND a.ModelDate <= convert(DATE, convert(VARCHAR,sold.DateSK, 112))
        GROUP BY a.InventoryLegSK,sold.DateSK
    ),
    maxbag20kg
    AS
    (
        SELECT a.InventoryLegID, MAX(a.ModelFromDatetime) AS ModelFromDatetime, sold.BookingDateTimeUTC
        FROM sold
            JOIN [datascience].[dbo_AncDynPricing_20kgPredictionsVersion] a
            ON a.InventoryLegID = sold.InventoryLegID
                AND a.[TripType] = 'POTENTIAL'
                and a.ModelFromDatetime <= sold.BookingDateTimeUTC
        GROUP BY a.InventoryLegID,sold.BookingDateTimeUTC
    ),
    ww
    AS
    (
        SELECT
            sold.InventoryLegSK
             , sold.InventoryLegID
             , sold.BookingSK
             , sold.DateSK
             , sold.BookingDateTimeUTC
             , sold.Passengers
             , sold.[20KGBagUnitsSold]
             , sold.[20KGBagChargesEUR]
             , sold.[10KGBagUnitsSold]
             , sold.[10KGBagChargesEUR]
             , sold.PBUnitsSold
             , sold.PBChargesEUR
             , pb.model_prices AS PB_model_price
             , (CASE WHEN bag10kg.ModelPrices < 0.45 * pr.ModelPrices THEN CEILING((0.45 *(pr.ModelPrices))/0.5)*0.5
             WHEN bag10kg.ModelPrices > 0.85 * pr.ModelPrices THEN CEILING((0.85 * pr.ModelPrices)/0.5)*0.5
             ELSE CEILING(bag10kg.ModelPrices/0.5)*0.5 END) AS bag10kg_model_price
             , pr.ModelPrices AS bag20kg_model_price
        FROM sold
            JOIN [datascience_rpt].[vw_AncDynPricing_PBPredictionsSnapshots] pb
            ON pb.[Trip Type] = 'POTENTIAL'
                AND sold.InventoryLegSK = pb.InventoryLegSK
                AND CONVERT(DATE, CONVERT(VARCHAR,sold.DateSK, 112)) = pb.ModelDate

            JOIN maxbag10kg ON maxbag10kg.InventoryLegSK = sold.InventoryLegSK AND maxbag10kg.DateSK = sold.DateSK

            JOIN ( SELECT InventoryLegSK, ModelDate, MAX(ModelPrices)  AS ModelPrices
            FROM [datascience_rpt].[vw_AncDynPricing_CBAGPredictionsSnapshots]
            --dups here/need max value
            WHERE [Trip Type] = 'POTENTIAL'
            GROUP BY InventoryLegSK, ModelDate) bag10kg
            ON maxbag10kg.InventoryLegSK = bag10kg.InventoryLegSK
                AND bag10kg.ModelDate = maxbag10kg.ModelDate

            JOIN maxbag20kg ON maxbag20kg.InventoryLegID = sold.InventoryLegID AND maxbag20kg.BookingDateTimeUTC = sold.BookingDateTimeUTC

            JOIN ( SELECT InventoryLegID, ModelFromDatetime, MAX(ModelPrices) AS ModelPrices
            FROM [datascience].[dbo_AncDynPricing_20kgPredictionsVersion]
            WHERE [TripType] = 'POTENTIAL'
            GROUP BY InventoryLegID, ModelFromDatetime) pr
            ON maxbag20kg.InventoryLegID = pr.InventoryLegID
                AND maxbag20kg.ModelFromDatetime = pr.ModelFromDatetime
    )

(select
    PB_model_price - bag10kg_model_price AS PB_10KG
    , PB_model_price - bag20kg_model_price AS PB_20KG
    , bag10kg_model_price - bag20kg_model_price AS bag10KG_20KG
    , sum(Passengers) AS PAX
    , sum(PBUnitsSold) AS Units_PB
    , sum(PBChargesEUR) AS Revenue_PB
    , SUM(PBUnitsSold) / SUM(Passengers) AS Conv_PB
    , SUM(PBChargesEUR)/NULLIF(SUM(Passengers), 0) AS RPP_PB
    , sum([10KGBagUnitsSold]) AS Units_10KG
    , sum([10KGBagChargesEUR]) AS Revenue_10KG
    , SUM([10KGBagUnitsSold]) / SUM(Passengers) AS Conv_10KG
    , SUM([10KGBagChargesEUR])/NULLIF(SUM(Passengers), 0) AS RPP_10KG
    , sum([20KGBagUnitsSold]) AS Units_20KG
    , sum([20KGBagChargesEUR]) as Revenue_20KG
    , SUM([20KGBagUnitsSold]) / SUM(Passengers) AS Conv_20KG
    , SUM([20KGBagChargesEUR])/NULLIF(SUM(Passengers), 0) AS RPP_20KG
    , SUM(PBUnitsSold + [10KGBagUnitsSold] + [20KGBagUnitsSold])/SUM(Passengers)   AS Combined_Conv
    , SUM(PBChargesEUR + [10KGBagChargesEUR] + [20KGBagChargesEUR])/SUM(Passengers) AS Combined_RPP
from ww
where PB_model_price is not null and bag10kg_model_price is not null and bag20kg_model_price is not null
group by PB_model_price - bag10kg_model_price, PB_model_price - bag20kg_model_price,bag10kg_model_price - bag20kg_model_price)
ORDER BY SUM(PBChargesEUR + [10KGBagChargesEUR] + [20KGBagChargesEUR])/SUM(Passengers) desc, SUM(PBUnitsSold + [10KGBagUnitsSold] + [20KGBagUnitsSold])/SUM(Passengers) desc