# Profil Data Sumber: Penjualan Reseller

Kelompok : 7
Query    : `sql/profil-data-sumber.sql` (nomor bagian di bawah sama dengan nomor di file SQL)
Database : `adventureworks2` di MySQL/MariaDB (XAMPP), hasil import dump dosen

> **Asal data.** Rincian lengkap ada di `docs/sumber-data.md`. Database berasal dari dump MariaDB `adventureworks2` dari dosen (AdventureWorks2017 dari Microsoft, build 14.0.1000.169), di-import apa adanya ke XAMPP. Nama tabel berbentuk `skema_tabel`, misalnya `sales_salesorderheader`.
>
> **Zona waktu.** Kolom bertipe TIMESTAMP (misalnya OrderDate) di dump tergeser −05:30 (tertulis `2011-05-30 18:30:00`, padahal aslinya `2011-05-31 00:00:00`). Semua query dijalankan setelah `SET time_zone = '+05:30';` sehingga OrderDate tampil sesuai data asli, tanpa mengubah isi database. Tanpa baris ini, di laptop WIB OrderDate tampil `01:30` dan perbandingan dengan kolom DATETIME (misalnya periode biaya produk) bisa meleset. Kolom DATETIME (DueDate, ShipDate) tidak terpengaruh.
>
> Setiap anggota wajib menjalankan bagian 1 dan memastikan hasilnya sama sebelum lanjut.
>
> Tangkapan layar hasil query dari laptop masing-masing anggota disimpan di `docs/bukti/` sebagai bukti untuk Steering Review.

## Ringkasan

| Ukuran | Nilai |
|--------|-------|
| Pesanan reseller | 3.806 |
| Calon baris fakta (baris pesanan) | 60.919 |
| Rentang tanggal pesanan reseller | 31 Mei 2011 sampai 1 Mei 2014 |
| Total nilai penjualan (USD) | 80.487.704,18 |
| Total unit | 214.516 |
| Total nilai diskon (USD) | 527.507,91 |
| Produk terjual | 250 dari 504 produk |
| Reseller yang pernah membeli | 635 dari 701 toko |
| Sales person | 17 (14 sales representative, 3 manajer) |
| Wilayah | 10 |
| Promosi dipakai | 12 |
| Mata uang | 5 (USD, CAD, GBP, EUR, AUD) |
| Metode kirim | 1 (CARGO TRANSPORT 5) |

## 1. Pesanan per kanal

| OnlineOrderFlag | Jumlah pesanan | Awal | Akhir |
|-----------------|----------------|------|-------|
| 0 (reseller) | 3.806 | 2011-05-31 | 2014-05-01 |
| 1 (online) | 27.659 | 2011-05-31 | 2014-06-30 |

## 2. Pesanan reseller per tahun

| Tahun | Pesanan | Pesanan pertama | Pesanan terakhir | Subtotal (USD) |
|-------|---------|-----------------|------------------|----------------|
| 2011 | 406 | 2011-05-31 | 2011-12-01 | 8.778.552,00 |
| 2012 | 1.172 | 2012-01-01 | 2012-12-31 | 27.133.701,38 |
| 2013 | 1.598 | 2013-01-28 | 2013-12-31 | 32.890.351,72 |
| 2014 | 630 | 2014-01-28 | 2014-05-01 | 11.685.099,08 |

2011 dan 2014 hanya sebagian tahun. Perbandingan antartahun di dashboard harus memberi tanda untuk dua tahun ini.

## 3. Calon baris fakta dan anggota dimensi

| Calon baris fakta | Pesanan | Produk | Reseller | Sales person | Wilayah | Promosi | Metode kirim | Kurs harian berbeda |
|---|---|---|---|---|---|---|---|---|
| 60.919 | 3.806 | 250 | 635 | 17 | 10 | 12 | 1 | 96 |

## 4. NULL di header pesanan reseller

| Kolom | Jumlah NULL | Keterangan |
|-------|-------------|------------|
| `SalesPersonID` | 0 | Semua pesanan reseller punya sales person |
| `TerritoryID` | 0 | |
| `CurrencyRateID` | 2.629 | NULL berarti transaksi dalam USD |
| `ShipDate` | 0 | |
| `PurchaseOrderNumber` | 0 | |
| `sales_customer.StoreID` | 0 | Semua pembeli reseller adalah toko |

## 5. Atribut produk yang terjual (250 produk)

| Atribut | Jumlah produk NULL |
|---------|--------------------|
| Subkategori | 0 |
| Model | 0 |
| Warna | 28 |
| Ukuran | 58 |
| Sudah tidak dijual (`SellEndDate` terisi) | 83 |

## 6 dan 7. Sales person dan perpindahan wilayah

- 3 manajer (Stephen Jiang, Syed Abbas, Amy Alberts) tidak punya `TerritoryID`, tetapi punya 103 pesanan reseller.
- 3 sales person pernah pindah wilayah pada Mei 2012 dan November 2012:

| Sales person | Wilayah lama | Wilayah baru | Pindah |
|--------------|--------------|--------------|--------|
| Michael Blythe (275) | 2 Northeast | 3 Central | 2012-11-30 |
| Jillian Carson (277) | 3 Central | 2 Northeast | 2012-11-30 |
| José Saraiva (282) | 6 Canada | 10 United Kingdom | 2012-05-30 |

## 8. Konsistensi sales person dan wilayah

| Pemeriksaan | Jumlah pesanan |
|-------------|----------------|
| Total pesanan | 3.806 |
| Sales person di pesanan ≠ sales person toko saat ini | 1.563 (41%) |
| Wilayah di pesanan ≠ wilayah sales person saat ini | 1.429 (38%) |

## 9. Reseller (toko)

| Ukuran | Nilai |
|--------|-------|
| Total toko | 701 |
| Toko yang pernah membeli | 635 |
| Toko dengan lebih dari satu alamat | 11 (Main Office dan Shipping) |
| Tipe bisnis BM (Value Added Reseller) | 238 toko |
| Tipe bisnis BS (Specialty Bike Shop) | 231 toko |
| Tipe bisnis OS (Warehouse) | 232 toko |

## 10. Wilayah

| ID | Wilayah | Negara | Grup | Pesanan |
|----|---------|--------|------|---------|
| 1 | Northwest | US | North America | 536 |
| 2 | Northeast | US | North America | 342 |
| 3 | Central | US | North America | 376 |
| 4 | Southwest | US | North America | 751 |
| 5 | Southeast | US | North America | 469 |
| 6 | Canada | CA | North America | 692 |
| 7 | France | FR | Europe | 188 |
| 8 | Germany | DE | Europe | 139 |
| 9 | Australia | AU | Pacific | 125 |
| 10 | United Kingdom | GB | Europe | 188 |

## 11 dan 12. Mata uang dan metode kirim

| Mata uang | Pesanan |
|-----------|---------|
| USD | 2.629 |
| CAD | 692 |
| GBP | 188 |
| EUR | 172 |
| AUD | 125 |

Hanya satu metode kirim yang dipakai: CARGO TRANSPORT 5 (3.806 pesanan).

Catatan: 154 pesanan di France dan 1 pesanan di Germany tercatat dalam USD, bukan EUR. Ini sesuai data sumber, bukan kesalahan query.

## 13. Promosi

| ID | Promosi | Jenis | Diskon | Baris |
|----|---------|-------|--------|-------|
| 1 | No Discount | No Discount | 0% | 57.637 |
| 2 | Volume Discount 11 to 14 | Volume Discount | 2% | 1.310 |
| 3 | Volume Discount 15 to 24 | Volume Discount | 5% | 606 |
| 4 | Volume Discount 25 to 40 | Volume Discount | 10% | 80 |
| 5 | Volume Discount 41 to 60 | Volume Discount | 15% | 2 |
| 7 | Mountain-100 Clearance Sale | Discontinued Product | 35% | 137 |
| 8 | Sport Helmet Discount-2002 | Seasonal Discount | 10% | 98 |
| 9 | Road-650 Overstock | Excess Inventory | 30% | 61 |
| 11 | Sport Helmet Discount-2003 | Seasonal Discount | 15% | 84 |
| 13 | Touring-3000 Promotion | New Product | 15% | 504 |
| 14 | Touring-1000 Promotion | New Product | 20% | 231 |
| 16 | Mountain-500 Silver Clearance Sale | Discontinued Product | 40% | 169 |

## 14. Biaya standar historis

| Ukuran | Baris |
|--------|-------|
| Baris detail reseller | 60.919 |
| Dapat biaya dari periode yang cocok | 60.855 |
| Tidak ada periode biaya yang cocok | 64 |
| Biaya historis berbeda dengan biaya terbaru | 14.387 |

Ke-64 baris berasal dari 25 produk yang terjual setelah periode biaya terakhirnya berakhir. Untuk produk ini, `production_product.StandardCost` sama dengan biaya periode terakhir, jadi aman dipakai sebagai cadangan.

## 15. Rekonsiliasi awal (angka acuan pekan 13)

| Ukuran | Nilai |
|--------|-------|
| `SUM(SubTotal)` di header | 80.487.704,18 |
| Total nilai dari detail (rumus) | 80.487.704,18 |
| `SUM(LineTotal)` | 80.487.704,18 |
| Selisih | 0 |
| Total nilai diskon | 527.507,91 |
| Total unit | 214.516 |

Nilai penjualan dihitung dengan rumus `OrderQty * UnitPrice * (1 - UnitPriceDiscount)`. Hasilnya sama persis dengan subtotal header dan dengan kolom `LineTotal`. Rumus tetap dipakai di ETL supaya aturan perhitungannya tertulis jelas dan tidak bergantung pada kolom turunan.

## Temuan dan dampaknya ke desain

| Temuan | Dampak ke desain atau ETL |
|--------|---------------------------|
| 41% pesanan punya sales person berbeda dengan sales person toko saat ini | `sales_person_key` diambil dari header pesanan |
| 38% pesanan punya wilayah berbeda dengan wilayah sales person saat ini, dan 3 sales person pernah pindah wilayah | `wilayah_key` diambil dari header pesanan. `dim_sales_person` kandidat SCD tipe 2 |
| 14.387 baris punya biaya historis berbeda dengan biaya terbaru | `total_biaya_produk` memakai `production_productcosthistory` sesuai tanggal pesan |
| Margin kotor total hanya 0,59%, negatif di 2013 dan 2014 | Pertanyaan P6 dan calculated member margin di cube |
| 11 toko punya dua alamat | `dim_reseller` memakai alamat Main Office |
| Warna dan ukuran kosong di sebagian produk | Diisi "Tidak ada" di `dim_produk` |
| Kolom TIMESTAMP di dump tergeser −05:30 | Setiap sesi query dan koneksi ETL memakai `SET time_zone = '+05:30'`. Dicek: pesanan pertama tampil 2011-05-31 00:00:00 |
| Nilai penjualan bisa dihitung dari rumus atau `LineTotal` | Rumus dipakai di ETL. Rekonsiliasi pakai `SUM(SubTotal)` header |
| Hanya satu metode kirim | Dimensi tetap dipakai karena conformed |
| 2011 dan 2014 tidak setahun penuh | Ditandai di dashboard saat membandingkan antartahun |
