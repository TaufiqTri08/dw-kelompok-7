# Laporan Progres Pekan 10

Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau
Disampaikan   : Steering Review pekan 10

## 1. Target dan capaian

| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Repositori dibuat dengan struktur folder standar, dosen diundang | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7 (folder `docs/`, `sql/`, `etl/`, `olap/`, `dashboard/`, `laporan/`; dosen sudah diundang sebagai collaborator) |
| Piagam proyek terisi lengkap, termasuk peran tiap anggota | Selesai | `docs/piagam-proyek.md` |
| Database sumber Adventure Works siap di laptop tiap anggota (MySQL XAMPP, database `adventureworks2`, lihat keputusan nomor 1) | Selesai (5 dari 5 anggota) | `sql/cek-kesiapan.sql` dijalankan di tiap laptop: 71 tabel, 31.465 pesanan, 3.806 pesanan reseller, 60.919 baris detail. Tangkapan layar per anggota dikumpulkan di `docs/bukti/` dengan nama `kesiapan-<nama>.png` (lihat `docs/bukti/README.md`) |
| Minimal 5 pertanyaan bisnis beserta fakta dan dimensinya | Selesai (5 pertanyaan) | `docs/pertanyaan-bisnis.md`, diuji dengan `sql/uji-pertanyaan-bisnis.sql` |
| Pernyataan grain dalam satu kalimat | Selesai | `docs/desain-star-schema-v1.md`, Langkah 2 |
| Star schema versi 1 | Selesai | `docs/star-schema-v1.png`, `docs/star-schema-v1.svg`, `docs/star-schema-v1.dbml` |
| Baris bus matrix tim | Selesai | `docs/bus-matrix.md` |
| Profil data sumber: jumlah baris, rentang tanggal, jumlah NULL | Selesai | `sql/profil-data-sumber.sql`, hasil di `docs/profil-data.md` |
| Minimal 3 risiko dan penanganannya | Selesai (10 risiko) | `docs/piagam-proyek.md` bagian 6 |
| Laporan pekan 10 ditulis dan disampaikan | Selesai | Dokumen ini, `laporan/pekan-10.md` |

Angka kunci dari profil data:

- 3.806 pesanan reseller, 60.919 baris detail (calon baris fakta), 31 Mei 2011 sampai 1 Mei 2014.
- Total nilai penjualan USD 80.487.704,18. Total dari rumus `OrderQty * UnitPrice * (1 - UnitPriceDiscount)` sama persis dengan `SUM(LineTotal)`, dan sama dengan `SUM(SubTotal)` header setelah dibulatkan ke sen (selisih di desimal ke-3: USD 0,004).
- Tidak ada NULL di sales person, wilayah, toko, dan tanggal kirim pada pesanan reseller. `CurrencyRateID` NULL di 2.629 pesanan (artinya USD).

## 2. Kendala pengerjaan

| No | Kendala | Yang sudah dicoba | Status |
|----|---------|-------------------|--------|
| 1 | Import dump lewat menu **Impor** phpMyAdmin gagal dengan pesan *"berkas yang terlalu besar"*. Dump berukuran 96 MB, melebihi batas upload phpMyAdmin di XAMPP. | Import lewat **Shell** XAMPP dengan perintah `mysql -u root adventureworks2 < dump.sql`. Hasilnya dicek dengan `sql/cek-kesiapan.sql`: 31.465 pesanan, 3.806 pesanan reseller, 71 tabel. | Selesai |
| 2 | Sekitar 100 perintah INSERT di dump berukuran hampir 1 MB (terbesar 1.045.756 byte), sangat dekat dengan batas `max_allowed_packet` bawaan XAMPP (1.048.576 byte). | `max_allowed_packet` dinaikkan menjadi 64M di `my.ini` sebelum import, sebagai pengaman. | Selesai |
| 3 | Contoh query di halaman tugas ditulis untuk PostgreSQL (`sales.salesorderheader`, `MIN(orderdate)::date`). Di MySQL muncul error `#1064`. | Semua query ditulis ulang ke sintaks MySQL: nama tabel `sales_salesorderheader`, `DATE(MIN(OrderDate))`, dan reseller ditandai `OnlineOrderFlag = 0`. Hasilnya sama dengan contoh di halaman tugas. | Selesai |
| 4 | Kolom TIMESTAMP (OrderDate) di dump tergeser −05:30. Tertulis `2011-05-30 18:30`, padahal data asli `2011-05-31 00:00`. Di laptop WIB, OrderDate tampil jam `01:30`. | Setiap sesi query diawali `SET time_zone = '+05:30'`, sehingga OrderDate tampil sesuai data asli tanpa mengubah isi database. Karena phpMyAdmin membuka sambungan baru setiap kali tombol **Kirim** ditekan, baris ini ditaruh di awal setiap file SQL. Hasilnya dicek: pesanan pertama tampil 2011-05-31. Tanpa baris ini, di laptop WIB tanggal tetap benar, tetapi di zona waktu UTC pesanan reseller 2011 terhitung 485 (seharusnya 406). | Selesai |
| 5 | Port AdventureWorks-for-Postgres di GitHub memakai tanggal 2022–2025, sedangkan dump dosen 2011–2014. Jumlah datanya sama, tetapi angka per tahun dan per kuartal berbeda. | Tim memakai dump dosen supaya angka sama dengan tim lain. Konfirmasi diminta di keputusan nomor 7. | Diajukan ke sponsor |
| 6 | Tipe bisnis reseller tersimpan sebagai teks XML di kolom `sales_store.Demographics`, bukan kolom biasa. | Isinya diambil dengan `SUBSTRING_INDEX`. Hasilnya dicek: BM 238, BS 231, OS 232 toko. | Selesai |
| 7 | Beberapa query memberi hasil salah **tanpa error**: menghitung baris detail tanpa menyaring reseller (121.317, seharusnya 60.919), membandingkan kolom yang bisa NULL dengan `<>` (1.326, seharusnya 1.429), `JOIN` biasa ke periode biaya produk (60.855 baris, seharusnya 60.919), dan `\|\|` yang di MySQL berarti OR, bukan penggabung teks. | Setiap jebakan diperbaiki dan dicatat beserta angkanya di `docs/catatan-sql.md`. | Selesai |
| 8 | Koneksi ke database sumber dari aplikasi Java/Pentaho memakai zona waktu UTC, sehingga tanggal pesanan mundur sehari. | Koneksi Pentaho memakai Advanced SQL `SET time_zone = '+05:30';`. Diuji di pekan 10 dengan `etl/Test Koneksi Pentaho.ktr`. | Selesai |

## 3. Kendala tim

- Tim berisi 5 orang dengan satu peran per orang. Karena beban tiap peran memuncak di pekan berbeda, anggota yang perannya sedang ringan membantu peran yang sedang sibuk.
- Pembagian tugas pekan berikutnya ditulis di `docs/pembagian-tugas-pekan-11.md` supaya tidak ada pekerjaan yang menumpuk di satu orang.
- Sebagian pekerjaan (setup database, pengujian query) dilakukan di laptop masing-masing dan tidak menghasilkan commit tersendiri; buktinya ditunjukkan langsung saat Steering Review.

## 4. Keputusan yang butuh persetujuan sponsor

1. **Database MySQL XAMPP, bukan PostgreSQL.** Halaman tugas menyebut PostgreSQL untuk database sumber. Tim memakai MySQL/MariaDB XAMPP untuk sumber maupun data warehouse, dengan dump `adventureworks2` dari dosen yang di-import apa adanya (data 2011–2014). Alasannya: satu jenis database untuk seluruh proyek, dan data sama persis dengan file dosen. Mohon persetujuan. Kalau sponsor meminta PostgreSQL, data bisa dipindahkan karena isinya sama.
2. **Grain dan delapan dimensi.** Grain satu baris per baris pesanan reseller, dengan 8 dimensi sesuai bus matrix kelas: Tanggal (3 peran: pesan, jatuh tempo, kirim), Produk, Reseller, Sales Person, Promosi, Wilayah, Mata Uang, dan Metode Kirim.
3. **Ongkos kirim dan pajak di luar lingkup v1.** Keduanya dicatat per pesanan. Jika dibutuhkan, kami usulkan alokasi proporsional ke baris berdasarkan nilai penjualan.
4. **Biaya produk historis.** `total_biaya_produk` memakai `production_productcosthistory` sesuai tanggal pesan, bukan biaya terbaru, karena 14.387 baris punya biaya yang berbeda.
5. **Sales person dari header pesanan**, bukan dari toko, karena 41% pesanan punya sales person yang berbeda dengan sales person toko saat ini. **Wilayah penjualan dari header pesanan**, karena sama dengan wilayah toko pada 3.806 dari 3.806 pesanan.
6. **Wilayah, mata uang, dan metode kirim dibuat sebagai dimensi sendiri.** Sesuai bus matrix kelas, ketiganya dipakai proses lain (Wilayah 4 proses, Metode Kirim 3, Mata Uang 2), sehingga dibuat sebagai dimensi conformed. Profil data menunjukkan isinya sedikit untuk proses reseller: semua pesanan memakai satu metode kirim (CARGO TRANSPORT 5), mata uang hanya 5 kode, dan wilayah pesanan sama dengan wilayah toko. Mohon sponsor mengonfirmasi struktur kolom ketiganya (usulan kami mengikuti kolom sumber) supaya sama dengan tim lain.
7. **Versi data.** Mohon konfirmasi bahwa semua tim memakai dump `adventureworks2` yang sama (data 2011–2014), agar angka rekonsiliasi antar-tim sama.

Keputusan 1, 3, 4, 5, dan 6 menjadi dasar kerja pekan 11. Keputusan 2 dan 7 tinggal menunggu konfirmasi sponsor.

## 5. Rencana pekan depan

| Target | Penanggung jawab |
|--------|------------------|
| Source-to-target mapping untuk setiap kolom dimensi dan fakta | Riki Audy Bin G (ETL Developer) |
| Strategi SCD tiap dimensi beserta alasannya (usulan tipe 2 untuk `dim_sales_person`) | Taufiq Tri W (Data Modeler) |
| Urutan load: staging, dimensi, lalu fakta | Riki Audy Bin G (ETL Developer) |
| Desain cube: dimensi, hierarki, dan measure, termasuk calculated member margin | Chandra Febryan Saputra (OLAP Developer) |
| Wireframe dashboard untuk kelima pertanyaan bisnis | Zaky (Dashboard Developer) |
| Star schema versi 2 setelah kesepakatan conformed dimension | Taufiq Tri W (Data Modeler) |
| Pentaho bisa dibuka dan terhubung ke MySQL XAMPP (driver JDBC MariaDB/MySQL, zona waktu sesi +05:30) di semua laptop | Semua anggota, dikoordinasi Anggoro Adit H |

Rincian pembagian tugas pekan 11 ada di `docs/pembagian-tugas-pekan-11.md`.

## 6. Kontribusi anggota

| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Anggoro Adit H | Project Manager | Piagam proyek, daftar risiko, laporan pekan 10, koordinasi kesiapan database | [`5a99483`](https://github.com/TaufiqTri08/dw-kelompok-7/commit/5a99483), [`a993417`](https://github.com/TaufiqTri08/dw-kelompok-7/commit/a993417) |
| Taufiq Tri W | Data Modeler | Pertanyaan bisnis, grain, star schema v1, bus matrix, profil data | [`003cee9`](https://github.com/TaufiqTri08/dw-kelompok-7/commit/003cee9), [`4259292`](https://github.com/TaufiqTri08/dw-kelompok-7/commit/4259292) |
| Riki Audy Bin G | ETL Developer | Setup database sumber, query profil data, catatan kendala SQL | Kerja di laptop anggota; tidak ada commit terpisah. Hasilnya dibuktikan lewat `sql/cek-kesiapan.sql` dan `docs/catatan-sql.md` |
| Chandra Febryan Saputra | OLAP Developer | Fakta dan dimensi tiap pertanyaan bisnis, daftar measure | Kerja di laptop anggota; tidak ada commit terpisah. Hasilnya dibuktikan di `docs/pertanyaan-bisnis.md` |
| Zaky | Dashboard Developer | Query uji pertanyaan bisnis dan temuan awal | Kerja di laptop anggota; tidak ada commit terpisah. Hasilnya dibuktikan di `docs/pertanyaan-bisnis.md` bagian "Hasil uji awal" |

Catatan: bukti commit diambil dari riwayat repositori. Pekerjaan yang tidak
menghasilkan berkas baru tetap dapat diperiksa lewat angka acuan dan tangkapan
layar yang ditunjukkan saat Steering Review.
