# Piagam Proyek Data Warehouse

Kelompok      : 7
Proses bisnis : Penjualan Reseller
Sponsor       : Mohamad Irwan Afandi, ST, M.Sc.
Tanggal       : 3 November 2026
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
5. Siapa 10 reseller dengan nilai penjualan terbesar, dan tipe bisnis reseller mana yang kontribusinya paling besar per tahun?
6. Produk dan kategori mana yang dijual ke reseller di bawah biaya standarnya, dan berapa total margin negatifnya per tahun?
7. Berapa porsi nilai penjualan reseller yang ditransaksikan dalam mata uang selain USD di tiap wilayah?

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

- Target atau kuota sales person (proses Kinerja Sales vs Target).
- Ongkos kirim dan pajak, karena dicatat per pesanan dan butuh alokasi ke baris (diajukan ke sponsor sebagai keputusan).
- Konversi nilai ke mata uang lokal. Semua nilai dalam USD.
- Load bertahap (incremental) dan penjadwalan otomatis. Versi ini memakai full load.

## 4. Tim dan peran

Semua anggota ikut di setiap tahap. Peran berarti penanggung jawab. Karena tim berisi 4 orang, peran OLAP Developer dan Dashboard Developer digabung.

| Nama | NPM | Peran utama |
|------|-----|-------------|
| Anggoro Adit H | 23082010006 | Project Manager (ketua tim) |
| Taufiq Tri Winardi | 23082010008 | Data Modeler |
| Riki Audy Bin G | 23082010011 | ETL Developer |
| Chandra Febryan Saputra | 23082010132 | OLAP dan Dashboard Developer |

## 5. Lingkungan teknis

| Komponen | Pilihan |
|----------|---------|
| Sumber | MySQL/MariaDB di XAMPP, database `adventureworks2` (hanya dibaca): AdventureWorks2017 dari Microsoft, dari dump dosen yang di-import apa adanya. Rincian di `docs/sumber-data.md` |
| Target | MySQL/MariaDB di XAMPP, database `dw_kelompok_x` |
| ETL | Pentaho Data Integration CE (versi sama untuk semua anggota) |
| OLAP | Mondrian |
| Dashboard | Web dengan chart library (usulan: Chart.js) |
| Repositori | Git, satu repositori tim `dw-kelompok-X` |



## Persetujuan

| | Nama | Tanggal | Paraf |
|---|---|---|---|
| Project Sponsor | Mohamad Irwan Afandi, ST, M.Sc. | | |
| Project Manager | Anggoro Adit H | | |
