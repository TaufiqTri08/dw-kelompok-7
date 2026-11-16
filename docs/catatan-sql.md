# Catatan Kesalahan SQL dan Perbaikannya

Kelompok : 7
Proses   : Penjualan Reseller
Sumber   : `adventureworks2` (MySQL/MariaDB XAMPP)

Dokumen ini mencatat query yang **memberi hasil salah tanpa pesan error**. Semua
angka di sini berasal dari `docs/profil-data.md` dan `sql/profil-data-sumber.sql`.
Tujuannya supaya anggota lain tidak mengulang kesalahan yang sama.

Selalu jalankan lebih dulu:

```sql
SET time_zone = '+05:30';
```

## 1. Lupa menyaring kanal reseller

`sales_salesorderdetail` berisi baris pesanan online **dan** reseller. Kalau
dihitung langsung, hasilnya 121.317 baris, padahal baris fakta yang benar 60.919.

```sql
-- SALAH: ikut menghitung penjualan online
SELECT COUNT(*) FROM sales_salesorderdetail;

-- BENAR: hanya pesanan reseller
SELECT COUNT(*)
FROM sales_salesorderdetail d
JOIN sales_salesorderheader h ON h.SalesOrderID = d.SalesOrderID
WHERE h.OnlineOrderFlag = 0;
```

## 2. Membandingkan kolom yang bisa NULL dengan `<>`

Perbandingan `a <> b` bernilai NULL (bukan TRUE) kalau salah satu sisinya NULL,
sehingga barisnya tidak ikut terhitung. Saat memeriksa selisih sales person
pesanan vs toko, hasilnya 1.326, padahal yang benar 1.429.

```sql
-- SALAH: 1.326 baris
WHERE h.SalesPersonID <> s.SalesPersonID

-- BENAR: 1.429 baris
WHERE NOT (h.SalesPersonID <=> s.SalesPersonID)

-- BENAR juga, lebih eksplisit
WHERE h.SalesPersonID IS NULL AND s.SalesPersonID IS NOT NULL
   OR h.SalesPersonID IS NOT NULL AND s.SalesPersonID IS NULL
   OR h.SalesPersonID <> s.SalesPersonID
```

## 3. JOIN biasa ke riwayat biaya produk

Biaya standar berubah per periode. `JOIN ... ON ProductID` saja akan
menggandakan baris atau memilih periode yang salah. Hasil uji awal 60.855 baris
(seharusnya 60.919), karena 64 baris tidak punya periode yang cocok.

```sql
-- SALAH: tidak melihat tanggal pesan, dan menghilangkan baris tanpa periode
JOIN production_productcosthistory ch ON ch.ProductID = d.ProductID

-- BENAR: cari periode yang memuat tanggal pesan
LEFT JOIN production_productcosthistory ch
       ON ch.ProductID = d.ProductID
      AND DATE(h.OrderDate) BETWEEN DATE(ch.StartDate) AND DATE(ch.EndDate)

-- Cadangan untuk 64 baris tanpa periode (lihat docs/mapping.md bagian 1.1)
COALESCE(ch.StandardCost, p.StandardCost)
```

## 4. `||` bukan penggabung teks di MySQL

Di PostgreSQL `||` menggabungkan teks. Di MySQL `||` berarti **OR**, sehingga
`FirstName || ' ' || LastName` menghasilkan 0/1, bukan nama.

```sql
-- SALAH di MySQL
SELECT FirstName || ' ' || LastName FROM person_person;

-- BENAR
SELECT CONCAT(FirstName, ' ', LastName) FROM person_person;
```

## 5. Nama tabel dan sintaks contoh tugas ditulis untuk PostgreSQL

Contoh di halaman tugas memakai `sales.salesorderheader` dan `MIN(orderdate)::date`.
Di MySQL muncul error `#1064`. Padanan yang dipakai tim:

| PostgreSQL | MySQL/MariaDB (dump dosen) |
|------------|----------------------------|
| `sales.salesorderheader` | `sales_salesorderheader` |
| `MIN(orderdate)::date` | `DATE(MIN(OrderDate))` |
| `ILIKE` | `LIKE` (collation sudah case-insensitive) |

## 6. Kolom `Group` adalah reserved word

`sales_salesterritory.Group` harus memakai backtick:

```sql
SELECT t.`Group` AS grup_wilayah FROM sales_salesterritory t;
```

## 7. Zona waktu sesi

Kolom TIMESTAMP di dump tergeser −05:30. Di laptop WIB tanggal masih benar,
tetapi di sesi UTC (misalnya koneksi Java/Pentaho) tanggal mundur sehari:
pesanan reseller 2011 menjadi 485 (seharusnya 406) dan 4.325 baris kehilangan
periode biaya (seharusnya 64). Perbaikannya `SET time_zone = '+05:30'` di awal
setiap sesi dan di Advanced SQL koneksi Pentaho.

## 8. Teks XML di `sales_store.Demographics`

Tipe bisnis, spesialisasi, tahun buka, dan jumlah karyawan tersimpan sebagai
teks XML, bukan kolom. Diambil dengan `SUBSTRING_INDEX`, contoh:

```sql
SUBSTRING_INDEX(SUBSTRING_INDEX(Demographics, '<BusinessType>', -1), '</BusinessType>', 1)
```

Hasil yang benar: BM 238, BS 231, OS 232 toko.

## 9. Angka acuan untuk memeriksa hasil

| Pemeriksaan | Nilai benar |
|-------------|-------------|
| Pesanan reseller | 3.806 |
| Baris detail reseller | 60.919 |
| Total nilai penjualan (USD) | 80.487.704,18 |
| Total unit | 214.516 |
| Baris dengan biaya historis cocok | 60.855 + 64 cadangan = 60.919 |
| Sales person pesanan ≠ sales person toko | 1.563 (41%) |
| Wilayah pesanan ≠ wilayah sales person | 1.429 (38%) |

Kalau hasil query berbeda dari tabel ini, periksa dulu penyebab di bagian 1–8
sebelum menyimpulkan datanya rusak.
