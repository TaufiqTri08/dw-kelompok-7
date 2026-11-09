# Piagam Proyek Data Warehouse

Kelompok      : X
Proses bisnis : Penjualan Reseller
Sponsor       : [nama dosen]
Tanggal       : [tanggal diajukan, pekan 10]
Versi         : 1

## 1. Latar belakang

Adventure Works menjual produknya lewat dua kanal: penjualan online ke perorangan dan penjualan reseller ke toko melalui sales person. Kanal reseller mencatat 3.806 pesanan dengan nilai sekitar USD 80,5 juta, tersebar di 635 toko, 17 sales person, dan 10 wilayah.

Saat ini manajemen tidak punya satu tempat untuk melihat kinerja kanal reseller per produk, sales person, wilayah, toko, dan promosi. Untuk menjawab satu pertanyaan sederhana seperti "penjualan per kategori per kuartal", analis harus menggabungkan 5 sampai 8 tabel di database operasional, menghitung sendiri nilai penjualan, dan mencari biaya produk yang berlaku saat itu. Hasilnya lambat, rumusnya bisa berbeda antar-laporan, dan query berat membebani sistem transaksi.

Profil data awal juga menunjukkan masalah yang perlu dilihat manajemen: margin kotor kanal reseller hanya 0,59% dan negatif di 2013 dan 2014, terutama di kategori Bikes. Manajemen butuh data warehouse untuk melihat di produk, wilayah, sales person, dan promosi mana margin itu tergerus.

## 2. Tujuan dan pertanyaan bisnis

Tujuan: membangun data warehouse penjualan reseller yang diisi lewat ETL, disajikan lewat OLAP cube, dan ditampilkan di dashboard, sehingga pertanyaan berikut bisa dijawab tanpa query ke database operasional.

1. Kategori dan subkategori produk apa yang nilai penjualan resellernya tumbuh paling cepat dari kuartal ke kuartal?
2. Sales person mana yang menghasilkan nilai penjualan dan margin kotor terbesar setiap tahun, dan berapa jumlah pesanannya?
3. Wilayah dan grup wilayah mana yang memberi nilai penjualan reseller terbesar, dan bagaimana trennya per tahun?
4. Jenis promosi mana yang memberi nilai diskon terbesar, untuk kategori produk apa, dan berapa unit yang terjual dengan promosi itu?
5. Produk dan kategori mana yang dijual ke reseller di bawah biaya standarnya, dan berapa total margin negatifnya per tahun?

Rincian fakta dan dimensi tiap pertanyaan ada di `docs/pertanyaan-bisnis.md`.

## 3. Ruang lingkup

**Masuk lingkup**

- Proses bisnis: penjualan reseller, yaitu pesanan dengan `OnlineOrderFlag = 0`.
- Rentang data: seluruh data pesanan reseller di sumber (31 Mei 2011 sampai 1 Mei 2014).
- Tabel sumber:
  - `sales_salesorderheader`, `sales_salesorderdetail`
  - `sales_customer`, `sales_store`
  - `sales_salesperson`, `sales_salesterritory`, `sales_salesterritoryhistory`
  - `sales_specialoffer`, `sales_currencyrate`, `sales_currency`
  - `purchasing_shipmethod`
  - `production_product`, `production_productsubcategory`, `production_productcategory`, `production_productmodel`, `production_productcosthistory`
  - `person_person`, `person_businessentityaddress`, `person_address`, `person_stateprovince`, `person_countryregion`
  - `humanresources_employee`
- Produk akhir: data warehouse (star schema), ETL Pentaho, cube Mondrian, dashboard web.

**Di luar lingkup**

- Penjualan online (dikerjakan tim lain).
- Target atau kuota sales person (proses Kinerja Sales vs Target).
- Ongkos kirim dan pajak, karena dicatat per pesanan dan butuh alokasi ke baris (diajukan ke sponsor sebagai keputusan).
- Konversi nilai ke mata uang lokal. Semua nilai dalam USD.
- Load bertahap (incremental) dan penjadwalan otomatis. Versi ini memakai full load.

## 4. Tim dan peran

Semua anggota ikut di setiap tahap. Peran berarti penanggung jawab. Tim berisi 5 orang, sehingga setiap peran dipegang satu orang.

| Nama | NPM | Peran utama |
|------|-----|-------------|
| Anggoro Adit H | [NPM] | Project Manager (ketua tim) |
| Taufiq Tri W | [NPM] | Data Modeler |
| Riki Audy Bin G | [NPM] | ETL Developer |
| Chandra Febryan Saputra | [NPM] | OLAP Developer |
| Zaky | [NPM] | Dashboard Developer |

Pembagian tugas dan aturan anggota untuk Steering Review pekan 11 ada di `docs/pembagian-tugas-pekan-11.md`.

## 5. Lingkungan teknis

| Komponen | Pilihan |
|----------|---------|
| Sumber | MySQL/MariaDB di XAMPP, database `adventureworks2` (hanya dibaca): AdventureWorks2017 dari Microsoft, dari dump dosen yang di-import apa adanya. Rincian di `docs/sumber-data.md` |
| Target | MySQL/MariaDB di XAMPP, database `dw_kelompok_x` |
| ETL | Pentaho Data Integration CE (versi sama untuk semua anggota) |
| OLAP | Mondrian |
| Dashboard | Web dengan chart library (usulan: Chart.js) |
| Repositori | Git, satu repositori tim `dw-kelompok-X` |

## 6. Risiko awal

| Risiko | Dampak | Rencana penanganan |
|--------|--------|--------------------|
| Sales person dan wilayah di pesanan berbeda dengan data toko dan sales person saat ini (41% dan 38% pesanan) | Penjualan tercatat ke sales person atau wilayah yang salah | Ambil `SalesPersonID` dari header pesanan. Wilayah penjualan diambil dari header pesanan (sama dengan wilayah toko pada semua 3.806 pesanan) dan disimpan di `dim_wilayah`. Wilayah tugas sales person disimpan dengan SCD tipe 2 di `dim_sales_person` |
| Biaya standar produk berubah dari waktu ke waktu (14.387 baris berbeda dengan biaya terbaru) | Margin salah hitung, padahal margin adalah temuan utama | Ambil biaya dari `production_productcosthistory` sesuai tanggal pesan, cadangan `production_product.StandardCost` untuk 64 baris tanpa periode |
| Versi database Adventure Works berbeda antar-anggota atau antar-tim (versi lain memakai tahun berbeda) | Angka profil dan rekonsiliasi tidak cocok antar-laptop | Semua anggota meng-import file dump dosen yang sama. Bagian 1 query profil harus menghasilkan angka yang sama sebelum lanjut |
| Kolom TIMESTAMP di dump tergeser −05:30, dan tampilannya bergantung pada zona waktu sesi | Di laptop WIB hanya jamnya yang salah. Tetapi kalau zona waktu sesi di bawah +05:30 (misalnya UTC di server atau Java), tanggal mundur sehari: angka per tahun salah dan 4.325 baris kehilangan periode biaya produk | Setiap sesi query dan koneksi Pentaho memakai `SET time_zone = '+05:30'`. Dicek: pesanan pertama tampil 2011-05-31 00:00:00 |
| Import dump gagal karena ukuran perintah (sekitar 1 MB) melewati batas `max_allowed_packet` bawaan XAMPP | Database sumber tidak lengkap di laptop anggota | Naikkan `max_allowed_packet=64M` di `my.ini` sebelum import, lalu cek jumlah tabel (71) dan pesanan (31.465) |
| Tugas menyebut PostgreSQL untuk database sumber, sedangkan tim memakai MySQL XAMPP | Sponsor tidak menyetujui pilihan database | Diajukan ke sponsor di laporan pekan 10. Kalau ditolak, dump bisa dipindahkan ke PostgreSQL karena isi datanya sama |
| Struktur `dim_produk` dan `dim_tanggal` belum disepakati kelas | Desain harus diubah setelah DDL dibuat | Tunggu kesepakatan pekan 10 sebelum menulis DDL. Hasilnya: sponsor menetapkan struktur standar untuk keduanya, dan DDL v2 mengikutinya |
| Pentaho tidak jalan di sebagian laptop (versi Java, memori) | ETL terlambat dibangun di pekan 12 | Semua anggota memasang versi installer yang sama, menambahkan driver JDBC MySQL/MariaDB, dan menguji koneksi ke XAMPP di pekan 10 |
| Beban kerja tiap peran memuncak di pekan berbeda (ETL di pekan 12, OLAP di pekan 13, dashboard di pekan 14) | Satu orang kewalahan sementara anggota lain menganggur, dan kontribusi di riwayat commit timpang | Setiap pekan, anggota yang perannya sedang ringan membantu peran yang sedang sibuk. Pembagian tugas dicatat di laporan progres |
| Nilai penjualan bisa diambil dari rumus atau kolom `LineTotal` | Rumus nilai penjualan bisa berbeda antar-anggota | Rumus tunggal ditulis di `docs/desain-star-schema-v1.md` dan dicek dengan rekonsiliasi ke `SUM(SubTotal)` |

## 7. Kriteria sukses

1. Total `nilai_penjualan` di data warehouse sama dengan `SUM(SubTotal)` pesanan reseller di sumber setelah dibulatkan ke sen (acuan saat ini: USD 80.487.704,18).
2. Jumlah baris `fact_penjualan_reseller` sama dengan jumlah baris detail pesanan reseller di sumber (acuan saat ini: 60.919).
3. Job ETL dijalankan dua kali tidak menghasilkan data ganda.
4. Kelima pertanyaan bisnis terjawab di dashboard, dan angkanya sama dengan hasil query MDX dan SQL pembanding (`sql/uji-pertanyaan-bisnis.sql`).
5. Seluruh produk bisa dijalankan ulang dari database sumber sampai dashboard dengan mengikuti panduan di repositori.

## Persetujuan

| | Nama | Tanggal | Paraf |
|---|---|---|---|
| Project Sponsor | [nama dosen] | | |
| Project Manager | Anggoro Adit H | | |
