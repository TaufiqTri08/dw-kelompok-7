-- =====================================================================
-- Uji Pertanyaan Bisnis langsung ke database sumber
-- Kelompok : X   |   Proses bisnis : Penjualan Reseller
-- Database : adventureworks2 (MySQL/MariaDB di XAMPP)
--
-- Tujuan:
--   1. Membuktikan setiap pertanyaan bisnis bisa diukur dari data sumber.
--   2. Menjadi angka pembanding saat rekonsiliasi (pekan 13) dan
--      saat mencocokkan hasil MDX (pekan 14).
--
-- Rumus yang dipakai (sama dengan rencana ETL):
--   nilai_penjualan    = OrderQty * UnitPrice * (1 - UnitPriceDiscount)
--   nilai_diskon       = OrderQty * UnitPrice * UnitPriceDiscount
--   total_biaya_produk = OrderQty * biaya standar yang berlaku pada OrderDate
--                        (production_productcosthistory; jika tidak ada
--                        periode yang cocok, pakai production_product.StandardCost)
-- Semua nilai uang dalam USD.
-- Butuh MariaDB 10.2+ atau MySQL 8+ (WITH dan LAG). XAMPP memakai MariaDB 10.4.
-- =====================================================================

-- Wajib paling awal (alasannya ada di sql/profil-data-sumber.sql bagian 0)
SET time_zone = '+05:30';


-- P1. Kategori produk: nilai penjualan per kuartal dan pertumbuhannya
WITH jual AS (
  SELECT pc.Name                AS kategori,
         YEAR(h.OrderDate)      AS tahun,
         QUARTER(h.OrderDate)   AS kuartal,
         SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)) AS nilai
  FROM sales_salesorderdetail d
  JOIN sales_salesorderheader h          ON h.SalesOrderID = d.SalesOrderID
  JOIN production_product p              ON p.ProductID = d.ProductID
  JOIN production_productsubcategory ps  ON ps.ProductSubcategoryID = p.ProductSubcategoryID
  JOIN production_productcategory pc     ON pc.ProductCategoryID = ps.ProductCategoryID
  WHERE h.OnlineOrderFlag = 0
  GROUP BY pc.Name, YEAR(h.OrderDate), QUARTER(h.OrderDate)
)
SELECT kategori, tahun, kuartal,
       ROUND(nilai, 2) AS nilai_penjualan,
       ROUND(100 * (nilai / LAG(nilai) OVER (PARTITION BY kategori ORDER BY tahun, kuartal) - 1), 1)
         AS pertumbuhan_persen
FROM jual
ORDER BY kategori, tahun, kuartal;


-- P2. Sales person: nilai penjualan, margin kotor, dan jumlah pesanan per tahun
WITH baris AS (
  SELECT h.SalesPersonID, h.SalesOrderID,
         YEAR(h.OrderDate) AS tahun,
         d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)    AS nilai,
         d.OrderQty * COALESCE(pch.StandardCost, p.StandardCost)  AS biaya
  FROM sales_salesorderdetail d
  JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
  JOIN production_product p     ON p.ProductID = d.ProductID
  LEFT JOIN production_productcosthistory pch
         ON pch.ProductID = d.ProductID
        AND h.OrderDate >= pch.StartDate
        AND (pch.EndDate IS NULL OR h.OrderDate <= pch.EndDate)
  WHERE h.OnlineOrderFlag = 0
)
SELECT b.tahun,
       CONCAT(pp.FirstName, ' ', pp.LastName) AS sales_person,
       COUNT(DISTINCT b.SalesOrderID)         AS jumlah_pesanan,
       ROUND(SUM(b.nilai), 2)                 AS nilai_penjualan,
       ROUND(SUM(b.nilai - b.biaya), 2)       AS margin_kotor
FROM baris b
JOIN person_person pp ON pp.BusinessEntityID = b.SalesPersonID
GROUP BY b.tahun, pp.FirstName, pp.LastName
ORDER BY b.tahun, nilai_penjualan DESC;


-- P3. Wilayah: nilai penjualan dan unit per tahun
SELECT t.`Group`          AS grup_wilayah,
       t.Name             AS wilayah,
       YEAR(h.OrderDate)  AS tahun,
       SUM(d.OrderQty)    AS jumlah_unit,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN sales_salesterritory t   ON t.TerritoryID  = h.TerritoryID
WHERE h.OnlineOrderFlag = 0
GROUP BY t.`Group`, t.Name, YEAR(h.OrderDate)
ORDER BY grup_wilayah, wilayah, tahun;


-- P4. Promosi: nilai diskon dan unit per jenis promosi dan kategori produk
SELECT so.Type        AS jenis_promosi,
       so.Description AS promosi,
       pc.Name        AS kategori,
       SUM(d.OrderQty) AS jumlah_unit,
       ROUND(SUM(d.OrderQty * d.UnitPrice * d.UnitPriceDiscount), 2) AS nilai_diskon
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h         ON h.SalesOrderID = d.SalesOrderID
JOIN sales_specialoffer so            ON so.SpecialOfferID = d.SpecialOfferID
JOIN production_product p             ON p.ProductID = d.ProductID
JOIN production_productsubcategory ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
JOIN production_productcategory pc    ON pc.ProductCategoryID = ps.ProductCategoryID
WHERE h.OnlineOrderFlag = 0
  AND d.UnitPriceDiscount > 0
GROUP BY so.Type, so.Description, pc.Name
ORDER BY nilai_diskon DESC;


-- P5a. 10 reseller dengan nilai penjualan terbesar
SELECT s.Name AS reseller,
       COUNT(DISTINCT h.SalesOrderID) AS jumlah_pesanan,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN sales_customer c         ON c.CustomerID = h.CustomerID
JOIN sales_store s            ON s.BusinessEntityID = c.StoreID
WHERE h.OnlineOrderFlag = 0
GROUP BY s.BusinessEntityID, s.Name
ORDER BY nilai_penjualan DESC
LIMIT 10;

-- P5b. Kontribusi per tipe bisnis reseller per tahun
SELECT CASE SUBSTRING_INDEX(SUBSTRING_INDEX(s.Demographics, '<BusinessType>', -1), '</BusinessType>', 1)
         WHEN 'BM' THEN 'Value Added Reseller'
         WHEN 'BS' THEN 'Specialty Bike Shop'
         WHEN 'OS' THEN 'Warehouse'
         ELSE 'Tidak diketahui'
       END AS tipe_bisnis,
       YEAR(h.OrderDate) AS tahun,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN sales_customer c         ON c.CustomerID = h.CustomerID
JOIN sales_store s            ON s.BusinessEntityID = c.StoreID
WHERE h.OnlineOrderFlag = 0
GROUP BY tipe_bisnis, YEAR(h.OrderDate)
ORDER BY tahun, nilai_penjualan DESC;


-- P6. Produk yang dijual di bawah biaya standar (margin negatif) per tahun
WITH baris AS (
  SELECT pc.Name AS kategori, p.Name AS produk,
         YEAR(h.OrderDate) AS tahun,
         d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)    AS nilai,
         d.OrderQty * COALESCE(pch.StandardCost, p.StandardCost)  AS biaya
  FROM sales_salesorderdetail d
  JOIN sales_salesorderheader h         ON h.SalesOrderID = d.SalesOrderID
  JOIN production_product p             ON p.ProductID = d.ProductID
  JOIN production_productsubcategory ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
  JOIN production_productcategory pc    ON pc.ProductCategoryID = ps.ProductCategoryID
  LEFT JOIN production_productcosthistory pch
         ON pch.ProductID = d.ProductID
        AND h.OrderDate >= pch.StartDate
        AND (pch.EndDate IS NULL OR h.OrderDate <= pch.EndDate)
  WHERE h.OnlineOrderFlag = 0
)
SELECT tahun, kategori, produk,
       ROUND(SUM(nilai), 2)          AS nilai_penjualan,
       ROUND(SUM(biaya), 2)          AS total_biaya,
       ROUND(SUM(nilai - biaya), 2)  AS margin_kotor
FROM baris
GROUP BY tahun, kategori, produk
HAVING SUM(nilai - biaya) < 0
ORDER BY tahun, SUM(nilai - biaya);


-- P7. Porsi penjualan per mata uang transaksi per wilayah
SELECT t.Name AS wilayah,
       COALESCE(cr.ToCurrencyCode, 'USD') AS mata_uang,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan_usd
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h   ON h.SalesOrderID = d.SalesOrderID
JOIN sales_salesterritory t     ON t.TerritoryID  = h.TerritoryID
LEFT JOIN sales_currencyrate cr ON cr.CurrencyRateID = h.CurrencyRateID
WHERE h.OnlineOrderFlag = 0
GROUP BY t.Name, mata_uang
ORDER BY wilayah, nilai_penjualan_usd DESC;
