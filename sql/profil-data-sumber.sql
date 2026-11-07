-- =====================================================================
-- Profil Data Sumber: Penjualan Reseller Adventure Works
-- Kelompok      : X
-- Database      : adventureworks2 (MySQL/MariaDB di XAMPP),
--                 hasil import dump dosen dump-adventureworks2-202509271927.sql
-- Tujuan        : memahami isi data sumber sebelum mendesain star schema.
--                 Database sumber hanya dibaca. Semua query di sini SELECT.
--
-- Penjualan reseller = pesanan dengan OnlineOrderFlag = 0.
-- Pesanan ini dibuat oleh sales person untuk sebuah toko (sales_store).
--
-- Cara menjalankan:
--   phpMyAdmin / HeidiSQL / DBeaver: pilih database adventureworks2,
--   jalankan baris SET time_zone dulu, lalu jalankan per bagian.
--   Command line (semua sekaligus):
--   mysql -u root adventureworks2 < sql\profil-data-sumber.sql
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0. WAJIB DIJALANKAN PALING AWAL: zona waktu sesi
--    Kolom OrderDate bertipe TIMESTAMP. MySQL menampilkan TIMESTAMP
--    sesuai zona waktu sesi. Di dump dosen, nilai TIMESTAMP tersimpan
--    tergeser -05:30, sehingga zona waktu sesi +05:30 mengembalikannya
--    ke nilai asli Adventure Works (pesanan pertama 2011-05-31 00:00:00).
--    Tanpa baris ini, di laptop WIB tanggal tetap benar tetapi jam tampil
--    01:30. Kalau zona waktu sesi di bawah +05:30 (misalnya UTC, yang
--    sering dipakai server atau aplikasi Java), tanggal mundur sehari:
--    pesanan reseller tahun 2011 terhitung 485, bukan 406, dan 4.325 baris
--    tidak menemukan periode biaya produk, bukan 64.
-- ---------------------------------------------------------------------
SET time_zone = '+05:30';


-- ---------------------------------------------------------------------
-- 1. Jumlah pesanan dan rentang tanggal per kanal penjualan
--    0 = reseller (lingkup kita), 1 = online (tim lain)
-- ---------------------------------------------------------------------
SELECT OnlineOrderFlag,
       COUNT(*)             AS jumlah_pesanan,
       DATE(MIN(OrderDate)) AS tanggal_awal,
       DATE(MAX(OrderDate)) AS tanggal_akhir
FROM sales_salesorderheader
GROUP BY OnlineOrderFlag
ORDER BY OnlineOrderFlag;


-- ---------------------------------------------------------------------
-- 2. Pesanan reseller per tahun
--    Menunjukkan tahun mana yang datanya penuh dan mana yang sebagian.
-- ---------------------------------------------------------------------
SELECT YEAR(OrderDate)         AS tahun,
       COUNT(*)                AS jumlah_pesanan,
       DATE(MIN(OrderDate))    AS pesanan_pertama,
       DATE(MAX(OrderDate))    AS pesanan_terakhir,
       ROUND(SUM(SubTotal), 2) AS total_subtotal_usd
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 0
GROUP BY YEAR(OrderDate)
ORDER BY tahun;


-- ---------------------------------------------------------------------
-- 3. Calon jumlah baris tabel fakta dan jumlah anggota tiap dimensi
--    Grain: satu baris per baris pesanan (sales_salesorderdetail).
-- ---------------------------------------------------------------------
SELECT COUNT(*)                         AS calon_baris_fakta,
       COUNT(DISTINCT h.SalesOrderID)   AS jumlah_pesanan,
       COUNT(DISTINCT d.ProductID)      AS produk_terjual,
       COUNT(DISTINCT c.StoreID)        AS reseller_pernah_beli,
       COUNT(DISTINCT h.SalesPersonID)  AS sales_person,
       COUNT(DISTINCT h.TerritoryID)    AS wilayah,
       COUNT(DISTINCT d.SpecialOfferID) AS promosi,
       COUNT(DISTINCT h.ShipMethodID)   AS metode_kirim,
       COUNT(DISTINCT h.CurrencyRateID) AS kurs_berbeda
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN sales_customer c         ON c.CustomerID   = h.CustomerID
WHERE h.OnlineOrderFlag = 0;


-- ---------------------------------------------------------------------
-- 4. NULL di kolom penting header pesanan reseller
--    COUNT(*) menghitung semua baris, COUNT(kolom) melewati NULL,
--    jadi selisihnya = jumlah NULL.
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                AS total_pesanan,
       COUNT(*) - COUNT(h.SalesPersonID)       AS null_salespersonid,
       COUNT(*) - COUNT(h.TerritoryID)         AS null_territoryid,
       COUNT(*) - COUNT(h.CurrencyRateID)      AS null_currencyrateid,
       COUNT(*) - COUNT(h.ShipDate)            AS null_shipdate,
       COUNT(*) - COUNT(h.PurchaseOrderNumber) AS null_purchaseordernumber,
       COUNT(*) - COUNT(c.StoreID)             AS null_storeid_di_customer
FROM sales_salesorderheader h
JOIN sales_customer c ON c.CustomerID = h.CustomerID
WHERE h.OnlineOrderFlag = 0;


-- ---------------------------------------------------------------------
-- 5. NULL di atribut produk yang terjual lewat reseller
--    Atribut ini akan masuk dim_produk.
-- ---------------------------------------------------------------------
SELECT COUNT(DISTINCT p.ProductID)                                                   AS produk_terjual,
       COUNT(DISTINCT CASE WHEN p.ProductSubcategoryID IS NULL THEN p.ProductID END)  AS null_subkategori,
       COUNT(DISTINCT CASE WHEN p.ProductModelID IS NULL THEN p.ProductID END)        AS null_model,
       COUNT(DISTINCT CASE WHEN p.Color IS NULL THEN p.ProductID END)                 AS null_warna,
       COUNT(DISTINCT CASE WHEN p.Size IS NULL THEN p.ProductID END)                  AS null_ukuran,
       COUNT(DISTINCT CASE WHEN p.SellEndDate IS NOT NULL THEN p.ProductID END)       AS sudah_tidak_dijual
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN production_product p     ON p.ProductID    = d.ProductID
WHERE h.OnlineOrderFlag = 0;


-- ---------------------------------------------------------------------
-- 6. Sales person: siapa saja, wilayahnya, dan jumlah pesanannya
--    Manajer tidak punya TerritoryID tetapi tetap punya pesanan.
--    (Di MySQL, NULL otomatis tampil paling atas saat diurutkan naik.)
-- ---------------------------------------------------------------------
SELECT sp.BusinessEntityID                     AS salespersonid,
       CONCAT(pp.FirstName, ' ', pp.LastName)  AS nama,
       e.JobTitle                              AS jabatan,
       sp.TerritoryID                          AS wilayah_saat_ini,
       COUNT(h.SalesOrderID)                   AS jumlah_pesanan
FROM sales_salesperson sp
JOIN person_person pp            ON pp.BusinessEntityID = sp.BusinessEntityID
JOIN humanresources_employee e   ON e.BusinessEntityID  = sp.BusinessEntityID
LEFT JOIN sales_salesorderheader h ON h.SalesPersonID   = sp.BusinessEntityID
                                  AND h.OnlineOrderFlag = 0
GROUP BY sp.BusinessEntityID, pp.FirstName, pp.LastName, e.JobTitle, sp.TerritoryID
ORDER BY wilayah_saat_ini, salespersonid;


-- ---------------------------------------------------------------------
-- 7. Sales person yang pernah pindah wilayah (kandidat SCD tipe 2)
-- ---------------------------------------------------------------------
SELECT sth.BusinessEntityID AS salespersonid,
       sth.TerritoryID,
       DATE(sth.StartDate)  AS mulai,
       DATE(sth.EndDate)    AS selesai
FROM sales_salesterritoryhistory sth
WHERE sth.BusinessEntityID IN (
        SELECT BusinessEntityID
        FROM sales_salesterritoryhistory
        GROUP BY BusinessEntityID
        HAVING COUNT(*) > 1)
ORDER BY salespersonid, mulai;


-- ---------------------------------------------------------------------
-- 8. Apakah sales person di pesanan sama dengan sales person toko saat ini?
--    Juga: apakah wilayah di pesanan sama dengan wilayah sales person saat ini?
--    Jika banyak yang berbeda, kunci dimensi harus diambil dari header pesanan.
--    (a <=> b artinya "a sama dengan b, NULL dianggap sama dengan NULL")
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS total_pesanan,
       SUM(CASE WHEN NOT (s.SalesPersonID <=> h.SalesPersonID) THEN 1 ELSE 0 END)
           AS sales_person_beda_dengan_toko,
       SUM(CASE WHEN NOT (sp.TerritoryID <=> h.TerritoryID) THEN 1 ELSE 0 END)
           AS wilayah_beda_dengan_sales_person
FROM sales_salesorderheader h
JOIN sales_customer c     ON c.CustomerID        = h.CustomerID
JOIN sales_store s        ON s.BusinessEntityID  = c.StoreID
JOIN sales_salesperson sp ON sp.BusinessEntityID = h.SalesPersonID
WHERE h.OnlineOrderFlag = 0;


-- ---------------------------------------------------------------------
-- 9. Toko (reseller): jumlah, yang pernah beli, dan jumlah alamat
--    Toko dengan lebih dari satu alamat perlu aturan pemilihan alamat.
-- ---------------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM sales_store) AS total_toko,
       (SELECT COUNT(DISTINCT c.StoreID)
          FROM sales_salesorderheader h
          JOIN sales_customer c ON c.CustomerID = h.CustomerID
         WHERE h.OnlineOrderFlag = 0)      AS toko_pernah_beli,
       (SELECT COUNT(*) FROM (
          SELECT bea.BusinessEntityID
          FROM person_businessentityaddress bea
          JOIN sales_store s ON s.BusinessEntityID = bea.BusinessEntityID
          GROUP BY bea.BusinessEntityID
          HAVING COUNT(*) > 1) x)          AS toko_alamat_lebih_dari_satu;

SELECT tipe.Name AS jenis_alamat,
       COUNT(*)  AS jumlah_toko
FROM sales_store s
JOIN person_businessentityaddress bea ON bea.BusinessEntityID = s.BusinessEntityID
JOIN person_addresstype tipe          ON tipe.AddressTypeID   = bea.AddressTypeID
GROUP BY tipe.Name
ORDER BY tipe.Name;

-- Tipe bisnis toko tersimpan di dalam teks XML kolom Demographics.
-- SUBSTRING_INDEX mengambil isi di antara <BusinessType> dan </BusinessType>.
-- BM = Value Added Reseller, BS = Specialty Bike Shop, OS = Warehouse
SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Demographics, '<BusinessType>', -1),
                       '</BusinessType>', 1) AS tipe_bisnis,
       COUNT(*) AS jumlah_toko
FROM sales_store
GROUP BY tipe_bisnis
ORDER BY tipe_bisnis;


-- ---------------------------------------------------------------------
-- 10. Wilayah penjualan reseller
--     `Group` ditulis dengan backtick karena GROUP adalah kata kunci SQL.
-- ---------------------------------------------------------------------
SELECT t.TerritoryID,
       t.Name              AS wilayah,
       t.CountryRegionCode AS kode_negara,
       t.`Group`           AS grup_wilayah,
       COUNT(*)            AS jumlah_pesanan
FROM sales_salesorderheader h
JOIN sales_salesterritory t ON t.TerritoryID = h.TerritoryID
WHERE h.OnlineOrderFlag = 0
GROUP BY t.TerritoryID, t.Name, t.CountryRegionCode, t.`Group`
ORDER BY t.TerritoryID;


-- ---------------------------------------------------------------------
-- 11. Mata uang transaksi
--     CurrencyRateID NULL berarti transaksi dalam USD.
-- ---------------------------------------------------------------------
SELECT COALESCE(cr.ToCurrencyCode, 'USD') AS mata_uang,
       COUNT(*)                           AS jumlah_pesanan
FROM sales_salesorderheader h
LEFT JOIN sales_currencyrate cr ON cr.CurrencyRateID = h.CurrencyRateID
WHERE h.OnlineOrderFlag = 0
GROUP BY mata_uang
ORDER BY jumlah_pesanan DESC;


-- ---------------------------------------------------------------------
-- 12. Metode kirim
-- ---------------------------------------------------------------------
SELECT sm.ShipMethodID,
       sm.Name  AS metode_kirim,
       COUNT(*) AS jumlah_pesanan
FROM sales_salesorderheader h
JOIN purchasing_shipmethod sm ON sm.ShipMethodID = h.ShipMethodID
WHERE h.OnlineOrderFlag = 0
GROUP BY sm.ShipMethodID, sm.Name;


-- ---------------------------------------------------------------------
-- 13. Promosi yang dipakai di baris pesanan reseller
-- ---------------------------------------------------------------------
SELECT so.SpecialOfferID,
       so.Description AS promosi,
       so.Type        AS jenis,
       so.DiscountPct AS persen_diskon,
       COUNT(*)       AS jumlah_baris
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID    = d.SalesOrderID
JOIN sales_specialoffer so    ON so.SpecialOfferID = d.SpecialOfferID
WHERE h.OnlineOrderFlag = 0
GROUP BY so.SpecialOfferID, so.Description, so.Type, so.DiscountPct
ORDER BY so.SpecialOfferID;


-- ---------------------------------------------------------------------
-- 14. Biaya standar historis
--     production_product.StandardCost hanya berisi biaya terbaru.
--     Biaya pada saat pesanan dibuat ada di production_productcosthistory.
-- ---------------------------------------------------------------------
SELECT COUNT(*)                            AS baris_detail,
       COUNT(pch.StandardCost)             AS dapat_biaya_historis,
       COUNT(*) - COUNT(pch.StandardCost)  AS tanpa_periode_biaya,
       SUM(CASE WHEN NOT (pch.StandardCost <=> p.StandardCost) THEN 1 ELSE 0 END)
                                           AS beda_dengan_biaya_terbaru
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN production_product p     ON p.ProductID    = d.ProductID
LEFT JOIN production_productcosthistory pch
       ON pch.ProductID = d.ProductID
      AND h.OrderDate  >= pch.StartDate
      AND (pch.EndDate IS NULL OR h.OrderDate <= pch.EndDate)
WHERE h.OnlineOrderFlag = 0;


-- ---------------------------------------------------------------------
-- 15. Rekonsiliasi awal (angka acuan untuk pekan 13)
--     Nilai dihitung dengan rumus yang sama dengan rencana ETL:
--     nilai_penjualan = OrderQty * UnitPrice * (1 - UnitPriceDiscount)
--     Rumus sama persis dengan SUM(LineTotal) (80487704.179188).
--     SUM(SubTotal) di header sedikit berbeda (80487704.1832) karena
--     SubTotal tiap pesanan dibulatkan ke 4 desimal. Setelah dibulatkan
--     ke sen (2 desimal), ketiganya sama: 80487704.18.
-- ---------------------------------------------------------------------
SELECT (SELECT ROUND(SUM(SubTotal), 2)
          FROM sales_salesorderheader
         WHERE OnlineOrderFlag = 0)                                         AS total_subtotal_header,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS total_nilai_detail,
       ROUND(SUM(d.LineTotal), 2)                                          AS total_linetotal,
       ROUND(SUM(d.OrderQty * d.UnitPrice * d.UnitPriceDiscount), 2)       AS total_nilai_diskon,
       SUM(d.OrderQty)                                                     AS total_unit
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
WHERE h.OnlineOrderFlag = 0;
