-- uji-dim-produk-scd2.sql | MySQL/MariaDB | Kelompok X | Penjualan Reseller
--
-- Dijalankan di database SUMBER (adventureworks2), bukan di DW. Hanya membaca: tabel v_produk adalah
-- TEMPORARY (hilang saat sesi ditutup), jadi isi database sumber tidak berubah.
--
-- Tujuan: membuktikan bahwa rancangan dim_produk standar sponsor (SCD tipe 2 pada biaya_standar dan harga_jual)
-- bisa dibangun dari sumber, dan bahwa fakta tetap menghasilkan angka rekonsiliasi yang sama.
-- Query bagian 1 sama dengan query Table input untuk dim_produk di docs/mapping.md.
--
-- Jalankan dari atas ke bawah di satu sesi (phpMyAdmin tab SQL, HeidiSQL, atau DBeaver Alt+X).

SET time_zone = '+05:30';

-- 1. Bangun semua versi produk -------------------------------------------------
-- Bagian A: produk yang punya riwayat biaya dan harga. Periode biaya dan periode harga di sumber identik
-- (395 = 395 baris, tanggal sama), jadi satu baris riwayat menjadi satu versi.
-- Periode TERAKHIR yang sudah ditutup di sumber diperpanjang sampai 9999-12-31: di production.product biaya dan
-- harga sekarang sama persis dengan periode terakhir itu (98 dari 98 produk), jadi tidak ada perubahan setelahnya.
-- Bagian B: produk tanpa riwayat (211, belum pernah dijual ke reseller) menjadi satu versi dengan biaya dan
-- harga dari production.product. Kosong dianggap 0.
DROP TEMPORARY TABLE IF EXISTS v_produk;
CREATE TEMPORARY TABLE v_produk AS
SELECT p.ProductID                       AS produk_id,
       p.Name                            AS nama_produk,
       p.ProductNumber                   AS nomor_produk,
       COALESCE(p.Color, 'Tidak ada')    AS warna,
       COALESCE(sc.Name, 'Tanpa kategori') AS subkategori,
       COALESCE(pc.Name, 'Tanpa kategori') AS kategori,
       COALESCE(ch.StandardCost, 0)      AS biaya_standar,
       COALESCE(ph.ListPrice, 0)         AS harga_jual,
       DATE(ch.StartDate)                AS berlaku_mulai,
       CASE WHEN ch.EndDate IS NULL
              OR ch.StartDate = (SELECT MAX(z.StartDate) FROM production_productcosthistory z WHERE z.ProductID = ch.ProductID)
            THEN DATE('9999-12-31') ELSE DATE(ch.EndDate) END AS berlaku_sampai
FROM production_product p
JOIN production_productcosthistory      ch ON ch.ProductID = p.ProductID
JOIN production_productlistpricehistory ph ON ph.ProductID = ch.ProductID AND ph.StartDate = ch.StartDate
LEFT JOIN production_productsubcategory sc ON sc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN production_productcategory    pc ON pc.ProductCategoryID = sc.ProductCategoryID
UNION ALL
SELECT p.ProductID, p.Name, p.ProductNumber, COALESCE(p.Color, 'Tidak ada'),
       COALESCE(sc.Name, 'Tanpa kategori'), COALESCE(pc.Name, 'Tanpa kategori'),
       COALESCE(p.StandardCost, 0), COALESCE(p.ListPrice, 0), DATE(p.SellStartDate), DATE('9999-12-31')
FROM production_product p
LEFT JOIN production_productsubcategory sc ON sc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN production_productcategory    pc ON pc.ProductCategoryID = sc.ProductCategoryID
WHERE p.ProductID NOT IN (SELECT ProductID FROM production_productcosthistory);

-- 2. Pemeriksaan bentuk dimensi ------------------------------------------------
-- 2.1 Jumlah versi dan produk. Harus: 606 versi, 504 produk.
SELECT COUNT(*) AS jumlah_versi, COUNT(DISTINCT produk_id) AS jumlah_produk FROM v_produk;

-- 2.2 Produk dengan lebih dari satu versi. Harus: 77.
SELECT COUNT(*) AS produk_banyak_versi
FROM (SELECT produk_id FROM v_produk GROUP BY produk_id HAVING COUNT(*) > 1) x;

-- 2.3 Setiap produk punya tepat satu versi berlaku sekarang (berlaku_sampai = 9999-12-31). Harus: 0 produk yang menyimpang.
SELECT COUNT(*) AS produk_menyimpang
FROM (SELECT produk_id FROM v_produk GROUP BY produk_id HAVING SUM(berlaku_sampai = '9999-12-31') <> 1) x;

-- 2.4 Periode tidak tumpang tindih dan tidak terbalik. Harus: 0 dan 0.
SELECT COUNT(*) AS tumpang_tindih
FROM v_produk a JOIN v_produk b
  ON a.produk_id = b.produk_id AND a.berlaku_mulai < b.berlaku_mulai AND a.berlaku_sampai >= b.berlaku_mulai;

SELECT COUNT(*) AS periode_terbalik FROM v_produk WHERE berlaku_mulai > berlaku_sampai;

-- 2.5 Panjang teks terbesar. Harus muat di kolom: nama 32 (batas 50), warna 12 (batas 15), nomor 10 (batas 25).
SELECT MAX(CHAR_LENGTH(nama_produk)) AS maks_nama, MAX(CHAR_LENGTH(warna)) AS maks_warna,
       MAX(CHAR_LENGTH(nomor_produk)) AS maks_nomor FROM v_produk;

-- 3. Pencarian produk_key untuk fakta (lewat tanggal pesan) --------------------
-- 3.1 Setiap baris fakta harus menemukan tepat satu versi. Harus: 60919 baris, 0 tanpa versi, 0 dengan lebih dari satu versi.
SELECT COUNT(*) AS baris_fakta,
       SUM(v.produk_id IS NULL) AS tanpa_versi
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
LEFT JOIN v_produk v ON v.produk_id = d.ProductID AND DATE(h.OrderDate) BETWEEN v.berlaku_mulai AND v.berlaku_sampai
WHERE h.OnlineOrderFlag = 0;

SELECT COUNT(*) AS baris_dengan_banyak_versi
FROM (SELECT d.SalesOrderDetailID
      FROM sales_salesorderdetail d
      JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
      JOIN v_produk v ON v.produk_id = d.ProductID AND DATE(h.OrderDate) BETWEEN v.berlaku_mulai AND v.berlaku_sampai
      WHERE h.OnlineOrderFlag = 0
      GROUP BY d.SalesOrderDetailID HAVING COUNT(*) > 1) x;

-- 3.2 Rekonsiliasi dengan biaya dari versi produk. Harus sama dengan angka acuan:
--     60919 baris, nilai 80487704.18, margin 476896.95 (biaya 80010807.2251).
SELECT COUNT(*) AS baris,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)), 2) AS nilai_penjualan,
       ROUND(SUM(d.OrderQty * v.biaya_standar), 4) AS total_biaya_produk,
       ROUND(SUM(d.OrderQty * d.UnitPrice * (1 - d.UnitPriceDiscount)) - SUM(d.OrderQty * v.biaya_standar), 2) AS margin_kotor
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
JOIN v_produk v ON v.produk_id = d.ProductID AND DATE(h.OrderDate) BETWEEN v.berlaku_mulai AND v.berlaku_sampai
WHERE h.OnlineOrderFlag = 0;

-- 3.3 Contoh: produk yang biayanya berubah, dilihat dari pesanan. Produk 707 (Sport-100 Helmet, Red).
SELECT v.produk_id, v.nama_produk, v.berlaku_mulai, v.berlaku_sampai, v.biaya_standar, v.harga_jual,
       COUNT(d.SalesOrderDetailID) AS baris_pesanan
FROM v_produk v
LEFT JOIN (sales_salesorderdetail d JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID AND h.OnlineOrderFlag = 0)
       ON d.ProductID = v.produk_id AND DATE(h.OrderDate) BETWEEN v.berlaku_mulai AND v.berlaku_sampai
WHERE v.produk_id = 707
GROUP BY v.produk_id, v.nama_produk, v.berlaku_mulai, v.berlaku_sampai, v.biaya_standar, v.harga_jual
ORDER BY v.berlaku_mulai;
