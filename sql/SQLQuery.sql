-----------------Query 1: cancellation rate by market segment---------------
use HotelBookings;

SELECT market_segment,
       COUNT(*) AS bookings,
       CAST(100.0 * SUM(is_canceled) / COUNT(*) AS decimal(5,1)) AS cancel_rate_pct
FROM hotel_bookings
GROUP BY market_segment
ORDER BY cancel_rate_pct DESC;

------Query 2: cancellation rate by arrival month---------
SELECT
    arrival_date_month,
    COUNT(*) AS bookings,
    SUM(is_canceled) AS cancelled,
    CAST(100.0 * SUM(is_canceled) / COUNT(*) AS decimal(5,1)) AS cancel_rate_pct
FROM dbo.hotel_bookings
GROUP BY arrival_date_month
ORDER BY CASE arrival_date_month
    WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3
    WHEN 'April' THEN 4 WHEN 'May' THEN 5 WHEN 'June' THEN 6
    WHEN 'July' THEN 7 WHEN 'August' THEN 8 WHEN 'September' THEN 9
    WHEN 'October' THEN 10 WHEN 'November' THEN 11 WHEN 'December' THEN 12
END;


--Query 3: cancellation rate by lead-time band-----

SELECT
    CASE
        WHEN TRY_CAST(lead_time AS int) < 30  THEN '1) 0-29 days'
        WHEN TRY_CAST(lead_time AS int) < 90  THEN '2) 30-89 days'
        WHEN TRY_CAST(lead_time AS int) < 180 THEN '3) 90-179 days'
        ELSE '4) 180+ days'
    END AS lead_time_band,
    COUNT(*) AS bookings,
    SUM(is_canceled) AS cancelled,
    CAST(100.0 * SUM(is_canceled) / COUNT(*) AS decimal(5,1)) AS cancel_rate_pct
FROM dbo.hotel_bookings
GROUP BY
    CASE
        WHEN TRY_CAST(lead_time AS int) < 30  THEN '1) 0-29 days'
        WHEN TRY_CAST(lead_time AS int) < 90  THEN '2) 30-89 days'
        WHEN TRY_CAST(lead_time AS int) < 180 THEN '3) 90-179 days'
        ELSE '4) 180+ days'
    END
ORDER BY lead_time_band;


----checks whether Groups is just a long-lead effect----
SELECT
    market_segment,
    CASE WHEN TRY_CAST(lead_time AS int) >= 90 THEN '90+ days' ELSE 'under 90 days' END AS lead_group,
    COUNT(*) AS bookings,
    CAST(100.0 * SUM(is_canceled) / COUNT(*) AS decimal(5,1)) AS cancel_rate_pct
FROM dbo.hotel_bookings
WHERE market_segment IN ('Groups','Online TA','Direct')
GROUP BY market_segment,
    CASE WHEN TRY_CAST(lead_time AS int) >= 90 THEN '90+ days' ELSE 'under 90 days' END
ORDER BY market_segment, lead_group;


----It estimates revenue on cancelled bookings, using ADR times nights, which is a “lost revenue” proxy, not actual losses----
SELECT
    CAST(SUM(adr * (TRY_CAST(stays_in_weekend_nights AS int) + TRY_CAST(stays_in_week_nights AS int))) AS decimal(14,0)) AS est_revenue_on_cancelled_bookings
FROM dbo.hotel_bookings
WHERE is_canceled = 1;

-----single table suits Tableau, since it supports all three charts (segment, lead band, and cost)------------
SELECT
    market_segment,
    CASE
        WHEN TRY_CAST(lead_time AS int) < 30  THEN '1) 0-29 days'
        WHEN TRY_CAST(lead_time AS int) < 90  THEN '2) 30-89 days'
        WHEN TRY_CAST(lead_time AS int) < 180 THEN '3) 90-179 days'
        ELSE '4) 180+ days'
    END AS lead_time_band,
    COUNT(*) AS bookings,
    SUM(is_canceled) AS cancelled,
    CAST(SUM(CASE WHEN is_canceled = 1
        THEN adr * (TRY_CAST(stays_in_weekend_nights AS int) + TRY_CAST(stays_in_week_nights AS int))
        ELSE 0 END) AS decimal(14,0)) AS est_revenue_on_cancelled
FROM dbo.hotel_bookings
WHERE market_segment <> 'Undefined'
GROUP BY market_segment,
    CASE
        WHEN TRY_CAST(lead_time AS int) < 30  THEN '1) 0-29 days'
        WHEN TRY_CAST(lead_time AS int) < 90  THEN '2) 30-89 days'
        WHEN TRY_CAST(lead_time AS int) < 180 THEN '3) 90-179 days'
        ELSE '4) 180+ days'
    END
ORDER BY market_segment, lead_time_band;
