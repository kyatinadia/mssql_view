ALTER VIEW dbo.kyatinadiayahoocom_view
AS
with 
master1 as (
    SELECT 
        c."Kota/Kabupaten",
        case 
        when c."Kota/Kabupaten" = 'ADM. KEPULAUAN SERIBU' then TRIM(RIGHT(c."Kota/Kabupaten",CHARINDEX('.', (REVERSE(c."Kota/Kabupaten"))) - 1))
        else c."Kota/Kabupaten"
        end as "trimkotakab",
        c."Bulan",
        c."Jumlah",
        IIF(c.Prevmonth = 0, '0.00%', CAST(CAST((c.Jumlah - c.Prevmonth) * 100.00 / c.Prevmonth AS DECIMAL(10, 2)) AS VARCHAR(10)) + '%') AS "Kenaikan Kedatangan Penduduk"
    FROM (
        SELECT 
            b.Kota "Kota/Kabupaten",
            b.Monthyear "Bulan",
            b.Jumlah, 
            LAG(b.Jumlah, 1,0) OVER (PARTITION BY b.Kota ORDER BY b.Month ASC) AS Prevmonth  
        FROM (
            SELECT
                a.[Kota/Kabupaten] "Kota",
                CONCAT(a.Bulan,' ', a.Tahun) as Monthyear,
                a.Month, 
                sum(a.Jumlah) "Jumlah" 
            FROM (
                SELECT
                    Kota_Kabupaten "Kota/Kabupaten",
                    CASE
                    WHEN STR(Month) = 1 THEN 'Jan'
                    WHEN STR(Month) = 2 THEN 'Feb'
                    WHEN STR(Month) = 3 THEN 'Mar'
                    WHEN STR(Month) = 4 THEN 'Apr'
                    WHEN STR(Month) = 5 THEN 'May'
                    WHEN STR(Month) = 6 THEN 'Jun'
                    WHEN STR(Month) = 7 THEN 'Jul'
                    WHEN STR(Month) = 8 THEN 'Aug'
                    WHEN STR(Month) = 9 THEN 'Sep'
                    WHEN STR(Month) = 10 THEN 'Oct'
                    WHEN STR(Month) = 11 THEN 'Nov'
                    WHEN STR(Month) = 12 THEN 'Dec'
                    END AS "Bulan",
                    Year "Tahun",
                    Month,
                    Jumlah
                FROM Kedatangan_Penduduk
            ) AS a
            GROUP BY a.[Kota/Kabupaten], CONCAT(a.Bulan,' ', a.Tahun), a.Month
        ) AS b
    ) AS c
),
master2 as (
    select
    Pejabat_Name,
    [Daerah Administratif] "Daerah_Administratif",
    Jabatan
from Pejabat
where Jabatan = 'Bupati'
)
select 
    master2.Pejabat_Name "Walikota/Bupati",
    master1."Kota/Kabupaten",
    left(master1.Bulan, 3) + '-' + right(year(master1.Bulan), 2) AS 'Bulan',
    master1.Jumlah "# Kedatangan Penduduk",
    master1."Kenaikan Kedatangan Penduduk" "Kenaikan Kedatangan Penduduk(%)",
    CASE 
        WHEN master1."Kenaikan Kedatangan Penduduk" BETWEEN '-90%' AND '-100%' or master1."Kenaikan Kedatangan Penduduk" = '0.00%' THEN 'Tidak Perlu Tempat Tinggal Baru'
        WHEN master1."Kenaikan Kedatangan Penduduk" BETWEEN '-50%' AND '-90%' THEN 'Perlu Tempat Tinggal Baru 1-2 Bulan'
        WHEN master1."Kenaikan Kedatangan Penduduk" BETWEEN '-50%' AND '50%' THEN 'Perlu Tempat Tinggal Baru Sekarang'
        WHEN master1."Kenaikan Kedatangan Penduduk" > '50%' THEN 'Perlu Tempat Tinggal Baru Sekarang'
    END AS "Status Urgensi Tempat Tinggal Baru"
from master1
right join master2 on master2.Daerah_Administratif = master1."trimkotakab";

