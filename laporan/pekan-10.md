# Laporan Progres Pekan 10
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau


## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Repositori dibuat dengan struktur folder standar, dosen diundang | [Selesai / Belum] | [tautan repositori] |
| Piagam proyek terisi lengkap, termasuk peran tiap anggota | Selesai | `docs/piagam-proyek.md` |
| Database sumber Adventure Works siap di laptop tiap anggota (MySQL XAMPP, database `adventureworks2`, lihat keputusan nomor 1) | [Selesai / x dari 4 anggota] |
| Minimal 5 pertanyaan bisnis beserta fakta dan dimensinya | Selesai (7 pertanyaan) | `docs/pertanyaan-bisnis.md`, diuji dengan `sql/uji-pertanyaan-bisnis.sql` |
| Pernyataan grain dalam satu kalimat | Selesai | `docs/desain-star-schema-v1.md`, Langkah 2 |
| Star schema versi 1 | Selesai | `docs/star-schema-v1.png`, `docs/star-schema-v1.dbml` |
| Baris bus matrix tim | Selesai | `docs/bus-matrix.md` |
| Profil data sumber: jumlah baris, rentang tanggal, jumlah NULL | Selesai | `sql/profil-data-sumber.sql`, hasil di `docs/profil-data.md` |

Angka kunci dari profil data:

- 3.806 pesanan reseller, 60.919 baris detail (calon baris fakta), 31 Mei 2011 sampai 1 Mei 2014.
- Total nilai penjualan USD 80.487.704,18. Total dari detail sama persis dengan `SUM(SubTotal)` header.
- Tidak ada NULL di sales person, wilayah, toko, dan tanggal kirim pada pesanan reseller. `CurrencyRateID` NULL di 2.629 pesanan (artinya USD).

## 2. Kendala pengerjaan
- Dump `adventureworks2` berukuran 96 MB, melebihi batas upload phpMyAdmin di XAMPP, dan ada satu perintah sekitar 1 MB yang hampir melewati batas `max_allowed_packet` bawaan. Solusinya: `max_allowed_packet` dinaikkan menjadi 64M dan import dilakukan lewat command line `mysql`.
- Kolom TIMESTAMP (OrderDate) di dump tergeser −05:30 (contoh: tertulis `2011-05-30 18:30`, seharusnya `2011-05-31 00:00`). Di laptop WIB, OrderDate tampil `01:30`. Solusinya: setiap sesi query diawali `SET time_zone = '+05:30'`, sehingga OrderDate tampil sesuai data asli tanpa mengubah isi database.
- Nilai penjualan dihitung dengan `OrderQty * UnitPrice * (1 - UnitPriceDiscount)`, lalu dicek ke `SUM(SubTotal)` header dan kolom `LineTotal`. Ketiganya cocok.
- Tipe bisnis reseller tersimpan sebagai teks XML di kolom `sales_store.Demographics`. Isinya diambil dengan `SUBSTRING_INDEX`.


## 3. Kendala tim
- Tim berisi 4 orang, sehingga peran OLAP dan Dashboard dirangkap satu orang. 


## 4. Keputusan yang butuh persetujuan sponsor
1. **Database MySQL XAMPP.** Tim memakai MySQL/MariaDB XAMPP untuk sumber maupun data warehouse, dengan dump `adventureworks2` dari dosen yang di-import apa adanya (data 2011–2014). Alasannya: satu jenis database untuk seluruh proyek, dan data sama persis dengan file dosen. Mohon persetujuan. 
2. **Grain dan dimensi.** Grain satu baris per baris pesanan reseller, dengan 8 dimensi: Tanggal (3 peran), Produk, Reseller, Sales Person, Wilayah, Promosi, Mata Uang, Metode Kirim.
3. **Ongkos kirim dan pajak di luar lingkup v1.** Keduanya dicatat per pesanan. Jika dibutuhkan, kami usulkan alokasi proporsional ke baris berdasarkan nilai penjualan.
4. **Biaya produk historis.** `total_biaya_produk` memakai `production_productcosthistory` sesuai tanggal pesan, bukan biaya terbaru, karena 14.387 baris punya biaya yang berbeda.
5. **Sales person dan wilayah dari header pesanan**, bukan dari toko, karena 41% pesanan punya sales person yang berbeda dengan sales person toko saat ini.
6. **`dim_metode_kirim` tetap dipakai** walaupun semua pesanan reseller memakai satu metode kirim, karena dimensi ini conformed.
7. **Versi data.** Mohon konfirmasi bahwa semua tim memakai dump `adventureworks2` yang sama (data 2011–2014), agar angka rekonsiliasi antar-tim sama.

## 5. Rencana pekan depan
| Target | Penanggung jawab |
|--------|------------------|
| Source-to-target mapping untuk setiap kolom dimensi dan fakta | Riki Audy Bin G ETL Developer |
| Strategi SCD tiap dimensi beserta alasannya (usulan tipe 2 untuk `dim_sales_person`) | Taufiq Tri W Data Modeler |
| Urutan load: staging, dimensi, lalu fakta | Riki Audy Bin G ETL Developer |
| Desain cube: dimensi, hierarki, dan measure, termasuk calculated member margin | Chandra Febryan Saputra OLAP dan Dashboard Developer |
| Wireframe dashboard untuk ketujuh pertanyaan bisnis | Chandra Febryan Saputra bersama Anggoro Adit H |
| Star schema versi 2 setelah kesepakatan conformed dimension | Taufiq Tri W Data Modeler |
| Pentaho bisa dibuka dan terhubung ke MySQL XAMPP (driver JDBC MariaDB/MySQL, zona waktu sesi +05:30) di semua laptop | Semua anggota, dikoordinasi Anggoro Adit H |

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Anggoro Adit H | Project Manager | piagam proyek, laporan pekan 10 | [hash commit] |
| Taufiq Tri W | Data Modeler | [contoh: pertanyaan bisnis, grain, star schema v1, bus matrix] | [hash commit] |
| Riki Audy Bin G | ETL Developer | [contoh: setup database, query profil data] | [hash commit] |
| Chandra Febryan Saputra | OLAP dan Dashboard Developer | [contoh: query uji pertanyaan bisnis, kamus data awal] | [hash commit] |
