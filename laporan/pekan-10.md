# Laporan Progres Pekan 10
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : [Hijau / Kuning / Merah]

> Pilih **Hijau** hanya jika semua baris di tabel 1 sudah berstatus Selesai, termasuk repositori, undangan ke dosen, dan database di laptop tiap anggota. Hapus catatan ini sebelum dikirim.

## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Repositori dibuat dengan struktur folder standar, dosen diundang | [Selesai / Belum] | [https://github.com/TaufiqTri08/dw-kelompok-7.git] |
| Piagam proyek terisi lengkap, termasuk peran tiap anggota | Selesai | `docs/piagam-proyek.md` |
| Database sumber Adventure Works siap di laptop tiap anggota (MySQL XAMPP, database `adventureworks2`, lihat keputusan nomor 1) | [Selesai / x dari 5 anggota] | `docs/bukti/kesiapan-<nama>.png` (hasil `sql/cek-kesiapan.sql` dari tiap laptop) |
| Minimal 5 pertanyaan bisnis beserta fakta dan dimensinya | Selesai (5 pertanyaan) | `docs/pertanyaan-bisnis.md`, diuji dengan `sql/uji-pertanyaan-bisnis.sql` |
| Pernyataan grain dalam satu kalimat | Selesai | `docs/desain-star-schema-v1.md`, Langkah 2 |
| Star schema versi 1 | Selesai | `docs/star-schema-v1.png`, `docs/star-schema-v1.dbml` |
| Baris bus matrix tim | Selesai | `docs/bus-matrix.md` |
| Profil data sumber: jumlah baris, rentang tanggal, jumlah NULL | Selesai | `sql/profil-data-sumber.sql`, hasil di `docs/profil-data.md` |
| Minimal 3 risiko dan penanganannya | Selesai (10 risiko) | `docs/piagam-proyek.md` bagian 6 |

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
| 5 | Port AdventureWorks-for-Postgres di GitHub memakai tanggal 2022–2025, sedangkan dump dosen 2011–2014. Jumlah datanya sama, tetapi angka per tahun dan per kuartal berbeda. | Tim memakai dump dosen supaya angka sama dengan tim lain. Konfirmasi diminta di keputusan nomor 7. | Menunggu konfirmasi |
| 6 | Tipe bisnis reseller tersimpan sebagai teks XML di kolom `sales_store.Demographics`, bukan kolom biasa. | Isinya diambil dengan `SUBSTRING_INDEX`. Hasilnya dicek: BM 238, BS 231, OS 232 toko. | Selesai |
| 7 | Beberapa query memberi hasil salah **tanpa error**: menghitung baris detail tanpa menyaring reseller (121.317, seharusnya 60.919), membandingkan kolom yang bisa NULL dengan `<>` (1.326, seharusnya 1.429), `JOIN` biasa ke periode biaya produk (60.855 baris, seharusnya 60.919), dan `\|\|` yang di MySQL berarti OR, bukan penggabung teks. | Setiap jebakan diperbaiki dan dicatat beserta angkanya di `docs/catatan-sql.md`. | Selesai |
| 8 | [Tambahkan kendala instalasi dari anggota lain, jika ada. Contoh: XAMPP MySQL tidak mau menyala karena port 3306 dipakai program lain.] | [Yang sudah dicoba] | [Selesai / Masih] |

## 3. Kendala tim
- Tim berisi 5 orang dengan satu peran per orang. Karena beban tiap peran memuncak di pekan berbeda, anggota yang perannya sedang ringan membantu peran yang sedang sibuk.
- [Tambahkan kendala komunikasi atau anggota yang sulit dihubungi, jika ada.]

## 4. Keputusan yang butuh persetujuan sponsor
1. **Database MySQL XAMPP, bukan PostgreSQL.** Halaman tugas menyebut PostgreSQL untuk database sumber. Tim memakai MySQL/MariaDB XAMPP untuk sumber maupun data warehouse, dengan dump `adventureworks2` dari dosen yang di-import apa adanya (data 2011–2014). Alasannya: satu jenis database untuk seluruh proyek, dan data sama persis dengan file dosen. Mohon persetujuan. Kalau sponsor meminta PostgreSQL, data bisa dipindahkan karena isinya sama.
2. **Grain dan lima dimensi.** Grain satu baris per baris pesanan reseller, dengan 5 dimensi: Tanggal (3 peran: pesan, jatuh tempo, kirim), Produk, Reseller (membawa wilayah penjualan toko), Sales Person, dan Promosi. Mata uang berupa kolom `kode_mata_uang` di fakta.
3. **Ongkos kirim dan pajak di luar lingkup v1.** Keduanya dicatat per pesanan. Jika dibutuhkan, kami usulkan alokasi proporsional ke baris berdasarkan nilai penjualan.
4. **Biaya produk historis.** `total_biaya_produk` memakai `production_productcosthistory` sesuai tanggal pesan, bukan biaya terbaru, karena 14.387 baris punya biaya yang berbeda.
5. **Sales person dari header pesanan**, bukan dari toko, karena 41% pesanan punya sales person yang berbeda dengan sales person toko saat ini. **Wilayah penjualan dari toko**, karena sama dengan wilayah di pesanan pada 3.806 dari 3.806 pesanan.
6. **Metode kirim, wilayah, dan mata uang tidak dibuat sebagai dimensi sendiri.** Semua pesanan reseller memakai satu metode kirim. Wilayah adalah atribut toko (tiap toko satu wilayah). Mata uang hanya lima kode. Konsekuensinya, di bus matrix ketiganya bukan dimensi conformed di sisi kami. Penggabungan dengan tim lain tetap bisa lewat atribut yang namanya dan isinya sama (`nama_wilayah`, `negara_wilayah`, `grup_wilayah`, `kode_mata_uang`). Mohon persetujuan, karena perlu disepakati dengan tim lain.
7. **Versi data.** Mohon konfirmasi bahwa semua tim memakai dump `adventureworks2` yang sama (data 2011–2014), agar angka rekonsiliasi antar-tim sama.

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

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Anggoro Adit H | Project Manager | Piagam proyek, daftar risiko, laporan pekan 10 | [hash commit] |
| Taufiq Tri W | Data Modeler | Pertanyaan bisnis, grain, star schema v1, bus matrix | [hash commit] |
| Riki Audy Bin G | ETL Developer | Setup database sumber, query profil data, catatan kendala SQL | [hash commit] |
| Chandra Febryan Saputra | OLAP Developer | Fakta dan dimensi tiap pertanyaan bisnis, daftar measure | [hash commit] |
| Muhammad Zakky Ulil Amry | Dashboard Developer | Query uji pertanyaan bisnis dan temuan awal | [hash commit] |
