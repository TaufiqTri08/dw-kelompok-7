-- uji-dim-wilayah-mata-uang-metode.sql | MySQL/MariaDB | Kelompok X
-- Jalankan di database SUMBER (adventureworks2), bukan di database DW. Hanya membaca, tidak mengubah apa pun.
-- Meniru hasil ETL untuk tiga dimensi yang dibangun dari tabel referensi kecil, lalu memeriksa bahwa
-- setiap baris fakta (60.919 baris detail pesanan reseller) menemukan tepat satu key di tiap dimensi.
-- Jalankan satu pemeriksaan dalam satu waktu bila memakai phpMyAdmin. Hasil yang diharapkan ada di komentar.

SET time_zone = '+05:30';

DROP TEMPORARY TABLE IF EXISTS v_wilayah;
DROP TEMPORARY TABLE IF EXISTS v_mata_uang;
DROP TEMPORARY TABLE IF EXISTS v_metode;

-- dim_wilayah: sales_salesterritory + nama negara dari person_countryregion
CREATE TEMPORARY TABLE v_wilayah AS
SELECT t.TerritoryID AS wilayah_id, t.Name AS nama_wilayah, t.CountryRegionCode AS kode_negara,
       c.Name AS nama_negara, t.`Group` AS grup_wilayah
FROM sales_salesterritory t
JOIN person_countryregion c ON c.CountryRegionCode = t.CountryRegionCode;

-- dim_mata_uang: semua kode di sales_currency
CREATE TEMPORARY TABLE v_mata_uang AS
SELECT CurrencyCode AS kode_mata_uang, Name AS nama_mata_uang FROM sales_currency;

-- dim_metode_kirim: semua metode di purchasing_shipmethod
CREATE TEMPORARY TABLE v_metode AS
SELECT ShipMethodID AS metode_id, Name AS nama_metode, ShipBase AS tarif_dasar, ShipRate AS tarif_per_kg
FROM purchasing_shipmethod;

-- 1. Jumlah baris tiap dimensi (belum termasuk baris -1)
-- Harus: 10 | 105 | 5
SELECT COUNT(*) AS baris_wilayah FROM v_wilayah;
SELECT COUNT(*) AS baris_mata_uang FROM v_mata_uang;
SELECT COUNT(*) AS baris_metode FROM v_metode;

-- 2. Fakta yang menemukan key. Wilayah dicari lewat TerritoryID header, mata uang lewat kurs
--    (kurs kosong = USD), metode lewat ShipMethodID.
-- Harus: 60919 baris fakta | 60919 | 60919 | 60919
SELECT COUNT(*) AS baris_fakta,
       SUM(w.wilayah_id IS NOT NULL) AS punya_wilayah,
       SUM(m.kode_mata_uang IS NOT NULL) AS punya_mata_uang,
       SUM(k.metode_id IS NOT NULL) AS punya_metode
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID AND h.OnlineOrderFlag = 0
LEFT JOIN v_wilayah w ON w.wilayah_id = h.TerritoryID
LEFT JOIN sales_currencyrate cr ON cr.CurrencyRateID = h.CurrencyRateID
LEFT JOIN v_mata_uang m ON m.kode_mata_uang = COALESCE(cr.ToCurrencyCode, 'USD')
LEFT JOIN v_metode k ON k.metode_id = h.ShipMethodID;

-- 3. Wilayah di header pesanan sama dengan wilayah toko (alasan wilayah tidak lagi disimpan di dim_reseller)
-- Harus: 3806 pesanan | 3806 sama
SELECT COUNT(*) AS pesanan, SUM(h.TerritoryID = c.TerritoryID) AS wilayah_sama
FROM sales_salesorderheader h
JOIN sales_customer c ON c.CustomerID = h.CustomerID
WHERE h.OnlineOrderFlag = 0;

-- 4. Rekonsiliasi nilai penjualan per grup wilayah. Jumlahnya harus sama dengan total sumber.
-- Harus: North America 3166 pesanan 67985726.79 | Europe 515 pesanan 10907642.01 | Pacific 125 pesanan 1594335.37
--        Total 80487704.18 (jumlah ketiga baris bisa berselisih 0,01 karena pembulatan per kelompok)
SELECT w.grup_wilayah,
       COUNT(DISTINCT h.SalesOrderID) AS pesanan,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID AND h.OnlineOrderFlag = 0
JOIN v_wilayah w ON w.wilayah_id = h.TerritoryID
GROUP BY w.grup_wilayah
ORDER BY nilai_penjualan DESC;

SELECT ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS total_nilai_penjualan
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID AND h.OnlineOrderFlag = 0
JOIN v_wilayah w ON w.wilayah_id = h.TerritoryID;

-- 5. Mata uang yang dipakai pesanan reseller
-- Harus: USD 2629 | CAD 692 | GBP 188 | EUR 172 | AUD 125 (jumlah 3806)
SELECT m.kode_mata_uang, m.nama_mata_uang, COUNT(DISTINCT h.SalesOrderID) AS pesanan
FROM sales_salesorderheader h
LEFT JOIN sales_currencyrate cr ON cr.CurrencyRateID = h.CurrencyRateID
JOIN v_mata_uang m ON m.kode_mata_uang = COALESCE(cr.ToCurrencyCode, 'USD')
WHERE h.OnlineOrderFlag = 0
GROUP BY m.kode_mata_uang, m.nama_mata_uang
ORDER BY pesanan DESC;

-- 6. Metode kirim yang dipakai pesanan reseller
-- Harus: satu baris, CARGO TRANSPORT 5, 3806 pesanan (4 metode lain ada di dimensi tetapi tidak terpakai)
SELECT k.metode_id, k.nama_metode, COUNT(*) AS pesanan
FROM sales_salesorderheader h
JOIN v_metode k ON k.metode_id = h.ShipMethodID
WHERE h.OnlineOrderFlag = 0
GROUP BY k.metode_id, k.nama_metode;

-- 7. Wilayah yang dipakai pesanan reseller
-- Harus: 10 wilayah, semuanya terpakai
SELECT COUNT(DISTINCT h.TerritoryID) AS wilayah_terpakai
FROM sales_salesorderheader h
WHERE h.OnlineOrderFlag = 0;
