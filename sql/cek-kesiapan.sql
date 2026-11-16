-- cek-kesiapan.sql | MySQL/MariaDB (XAMPP) | Kelompok 7 | Penjualan Reseller
-- Tujuan : memastikan database sumber sudah ter-import lengkap dan benar
--          di laptop setiap anggota SEBELUM mengerjakan tugas berikutnya.
-- Cara   : jalankan file ini di database `adventureworks2` (bukan di DW).
--          phpMyAdmin : pilih database adventureworks2 > tab SQL > tempel seluruh isi file > Go
--          Shell      : mysql -u root -t adventureworks2 < sql\cek-kesiapan.sql
-- Setiap baris hasil harus sama dengan kolom `acuan`. Kalau ada yang berbeda,
-- database sumber di laptop itu belum siap; ulangi langkah import di README.md.

SET time_zone = '+05:30';

SELECT 'jumlah tabel' AS pemeriksaan, COUNT(*) AS hasil, 71 AS acuan
FROM information_schema.tables
WHERE table_schema = DATABASE()

UNION ALL

SELECT 'baris sales_salesorderheader', COUNT(*), 31465
FROM sales_salesorderheader

UNION ALL

SELECT 'pesanan reseller (OnlineOrderFlag = 0)', COUNT(*), 3806
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 0

UNION ALL

SELECT 'baris detail reseller (calon baris fakta)', COUNT(*), 60919
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
WHERE h.OnlineOrderFlag = 0

UNION ALL

SELECT 'subtotal reseller dalam sen (USD)', ROUND(SUM(SubTotal) * 100), 8048770418
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 0

UNION ALL

SELECT 'tanggal pesanan reseller pertama (YYYYMMDD)',
       CAST(DATE_FORMAT(MIN(OrderDate), '%Y%m%d') AS UNSIGNED), 20110531
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 0

UNION ALL

SELECT 'tanggal pesanan reseller terakhir (YYYYMMDD)',
       CAST(DATE_FORMAT(MAX(OrderDate), '%Y%m%d') AS UNSIGNED), 20140501
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 0

UNION ALL

SELECT 'jumlah toko reseller (sales_store)', COUNT(*), 701
FROM sales_store

UNION ALL

SELECT 'jumlah produk (production_product)', COUNT(*), 504
FROM production_product;

-- Catatan: jumlah tabel 71 dihitung dari dump dosen. Kalau hasilnya 72 karena
-- ada tabel tambahan buatan sendiri di database yang sama, hapus dulu tabel itu
-- atau bandingkan daftar tabelnya dengan docs/sumber-data.md.
