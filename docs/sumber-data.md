# Sumber Data

Kelompok : X
Proses bisnis : Penjualan Reseller

## 1. Data asli

| Hal | Keterangan |
|-----|------------|
| Nama | Adventure Works (database contoh OLTP) |
| Pembuat | Microsoft |
| Isi | Perusahaan fiktif produsen dan penjual sepeda: penjualan, produk, produksi, pembelian, karyawan |
| Versi yang kami pakai | **AdventureWorks2017**, build `14.0.1000.169` (22 Agustus 2017) |
| Rentang data penjualan | 31 Mei 2011 sampai 30 Juni 2014 (reseller: 31 Mei 2011 sampai 1 Mei 2014) |
| Format asli | File backup SQL Server (`.bak`) dan install script |
| Tempat unduh resmi | Microsoft Learn: *AdventureWorks sample databases* (https://learn.microsoft.com/sql/samples/adventureworks-install-configure) dan rilis GitHub `microsoft/sql-server-samples`, tag `adventureworks` (https://github.com/microsoft/sql-server-samples/releases/tag/adventureworks) |

Bukti versi ada di dalam database itu sendiri:

```sql
-- versi build Adventure Works
SELECT * FROM dbo_awbuildversion;
-- hasil: 14.0.1000.169, tanggal versi 2017-08-22

-- nama database asal yang tercatat di log DDL Microsoft
SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(XmlEvent, '<DatabaseName>', -1),
                                '</DatabaseName>', 1) AS database_asal
FROM dbo_databaselog;
-- hasil: AdventureWorks2017
```

## 2. File yang kami terima

| Hal | Keterangan |
|-----|------------|
| File | `dump-adventureworks2-202509271927.sql` (sekitar 96 MB) |
| Diperoleh dari | Dosen pengampu mata kuliah |
| Format | Dump MariaDB/MySQL (`MySQL dump 10.13`, server `11.3.2-MariaDB`), database `adventureworks2` |
| Dibuat | 27 September 2025 |
| Isi | 71 tabel, 760.837 baris. Nama tabel berbentuk `skema_tabel`, misalnya `sales_salesorderheader` |

## 3. Cara kami memakainya

Dump di-import **apa adanya** ke MySQL/MariaDB di XAMPP, ke database bernama `adventureworks2`. Tidak ada konversi dan tidak ada data yang diubah. Langkahnya ada di `README.md`.

Ada dua hal yang perlu diperhatikan.

**a. Batas ukuran paket.** Sekitar 100 perintah INSERT di dump berukuran hampir 1 MB. Yang terbesar 1.045.756 byte, hanya sekitar 2.800 byte di bawah batas bawaan `max_allowed_packet=1M` (1.048.576 byte). Sebagai pengaman, batas ini dinaikkan menjadi 64M di `my.ini` sebelum import.

**b. Zona waktu kolom TIMESTAMP.**

- Kolom bertipe **TIMESTAMP** (misalnya `OrderDate` dan `ModifiedDate`) di dump tercatat tergeser **−05:30**. Contohnya, OrderDate pesanan pertama tertulis `2011-05-30 18:30:00`, padahal data Microsoft aslinya `2011-05-31 00:00:00`. Pergeserannya seragam: semua 31.465 OrderDate berakhir di jam 18:30:00.
- MySQL menyimpan TIMESTAMP dalam UTC dan menampilkannya sesuai **zona waktu sesi**. Dump memakai `TIME_ZONE='+00:00'`, sehingga nilainya tersimpan sebagai UTC.
- Tanpa pengaturan apa pun, laptop berzona WIB (+07:00) menampilkan `2011-05-31 01:30:00`. Tanggalnya benar dan hasil query tugas ini tetap sama (sudah dicek), hanya jamnya yang salah.
- Masalah sebenarnya muncul kalau zona waktu sesi **di bawah +05:30**, misalnya UTC, yang sering dipakai server atau aplikasi Java seperti Pentaho. Tanggal pesanan mundur sehari: pesanan 1 Januari 2012 terhitung ke 2011 (pesanan reseller 2011 menjadi 485, bukan 406), dan 4.325 baris tidak menemukan periode biaya di `production_productcosthistory` (seharusnya hanya 64), sehingga margin salah.
- Karena itu, setiap sesi query dimulai dengan:
  ```sql
  SET time_zone = '+05:30';
  ```
  Dengan pengaturan ini, OrderDate tampil persis seperti data Microsoft asli (`2011-05-31 00:00:00`), **tanpa mengubah isi database**.
- Kolom bertipe DATETIME (`DueDate`, `ShipDate`, `StartDate`, `EndDate`) tidak terpengaruh zona waktu.
- Catatan untuk pekan 12: koneksi Pentaho ke database sumber juga harus memakai zona waktu sesi +05:30.

## 4. Pemeriksaan hasil import

| Pemeriksaan | Hasil acuan |
|-------------|-------------|
| Jumlah tabel di `adventureworks2` | 71 |
| `SELECT COUNT(*) FROM sales_salesorderheader` | 31.465 |
| Pesanan reseller (`OnlineOrderFlag = 0`) | 3.806 |
| Tanggal pesanan reseller pertama (setelah `SET time_zone`) | 2011-05-31 |
| Total penjualan reseller | `SUM(SubTotal)` = `SUM(LineTotal)` = USD 80.487.704,18 (dibulatkan ke sen) |
| Contoh satu baris: `SalesOrderID = 43659` | `SO43659`, `PO522145787`, SubTotal 20565.6206 |

Semua hasil query acuan ada di `docs/hasil-query/`.

## 5. Alternatif yang tidak dipakai

- **PostgreSQL dengan port AdventureWorks-for-Postgres** (https://github.com/lorint/AdventureWorks-for-Postgres), yang disebut di halaman tugas. Port ini memakai install script terbaru Microsoft, yang tanggalnya bergeser ke 2022–2025, sehingga angka per tahun dan per kuartal berbeda dengan data dosen.
- **Mengonversi dump dosen ke PostgreSQL.** Cara ini sempat dicoba dan hasilnya sama, tetapi tim memutuskan memakai MySQL XAMPP untuk seluruh proyek supaya satu jenis database saja. Keputusan ini diajukan ke sponsor di laporan pekan 10.

## 6. Aturan pemakaian

- Database `adventureworks2` hanya dibaca. Tidak ada INSERT, UPDATE, atau DELETE.
- Semua anggota meng-import file dump yang sama. Bagian 1 `sql/profil-data-sumber.sql` harus menghasilkan 3.806 pesanan reseller dan tanggal awal 2011-05-31.
