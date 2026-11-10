# Laporan Progres Pekan 11
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau


## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Perbaiki star schema menjadi versi 2
Ikuti catatan sponsor dari Steering Review hari ini. Pakai struktur dim_tanggal standar apa adanya. Sesuaikan dim_produk dengan struktur standar.
 | Selesai | [`docs/mapping.md` bagian 1](https://github.com/TaufiqTri08/dw-kelompok-7/blob/c5a0b306546e918b897e4bb6b01da6c8b029a3f7/docs/mapping.md) |
| Strategi SCD tiap dimensi (tipe 0, 1, atau 2) beserta alasannya | Selesai | `docs/mapping.md` bagian 2 |
| Urutan load: staging, dimensi, lalu fakta | Selesai | `docs/mapping.md` bagian 3 |
| Desain cube: dimensi, hierarki, measure, calculated member margin | Selesai | `docs/desain-cube-dashboard.md` bagian 1 |
| Wireframe dashboard untuk kelima pertanyaan bisnis | Selesai | `docs/wireframe-dashboard.png`, rincian panel di `docs/desain-cube-dashboard.md` bagian 2 |
| Star schema versi 2 | Selesai | `docs/star-schema-v2.png`, `docs/star-schema-v2.dbml`, `docs/narasi-star-schema.md` |
| Pentaho terhubung ke database sumber `adventureworks2` (MySQL XAMPP, zona waktu sesi +05:30) di laptop tiap anggota | Selesai |  |

Perubahan dari star schema v1 ke v2:

- `dim_sales_person` memakai SCD tipe 2 (kolom `berlaku_mulai`, `berlaku_sampai`, `is_current`). Alasannya: tiga sales person pindah wilayah. José Saraiva punya 100 pesanan saat bertugas di Canada dan 171 pesanan sesudah pindah ke United Kingdom.
- `dim_produk` disesuaikan dengan **struktur standar sponsor** (12 kolom): `biaya_standar` dan `harga_jual` memakai SCD tipe 2, ditambah `berlaku_mulai`, `berlaku_sampai`, `is_current`. Kolom usulan v1 `ukuran`, `garis_produk`, `model`, `harga_list`, `status_jual` dihapus karena tidak dipakai kelima pertanyaan bisnis. 77 produk berganti biaya atau harga, sehingga dimensi berisi 606 baris untuk 504 produk.
- Jumlah dimensi tetap **delapan** seperti v1: Tanggal, Produk, Reseller, Sales Person, Promosi, Wilayah, Mata Uang, dan Metode Kirim (sesuai bus matrix kelas). Dimensi lain memakai SCD tipe 1: `dim_reseller`, `dim_promosi`, `dim_wilayah`, `dim_mata_uang`, dan `dim_metode_kirim`.
- `dim_tanggal` memakai skrip standar sponsor v1.0 apa adanya (`sql/dim_tanggal_mysql.sql`, 12 kolom, 2.192 baris), menggantikan kolom perkiraan di v1.

Angka kunci:

- Mapping mencakup 8 dimensi dan 1 fakta (60.919 baris, 10 key di fakta), ditulis dengan templat mapping dari dosen. `dim_sales_person` berisi 20 versi dari 17 sales person, dan `dim_produk` 606 versi dari 504 produk.
- Urutan load: dim_tanggal dan DDL, staging, dimensi tipe 1, dimensi tipe 2 (`dim_produk`, `dim_sales_person`), fakta, rekonsiliasi.
- Angka rekonsiliasi untuk ETL: 60.919 baris fakta, 3.806 pesanan, nilai penjualan USD 80.487.704,18, margin kotor USD 476.896,95.
- Cube: 7 measure (termasuk jumlah pesanan dengan distinct-count dan harga satuan dengan avg) dan 4 calculated member.
- Daftar tabel staging: 22 tabel.

## 2. Kendala pengerjaan
| No | Kendala | Yang sudah dicoba | Status |
|----|---------|-------------------|--------|
| 1 | Satu sales person bisa muncul beberapa kali di dimensi (SCD tipe 2), sehingga di cube level Sales Person bisa terhitung dobel. | Level Sales Person di cube memakai `sales_person_id` sebagai key dan nama sebagai caption, sehingga total per orang menyatu walaupun pindah wilayah. | Selesai |
| 2 | Pencarian `sales_person_key` di ETL harus memakai tanggal pesan, bukan hanya `SalesPersonID`. | Aturan pencarian ditulis di mapping fakta: `SalesPersonID` sama dan tanggal pesan di antara `berlaku_mulai` dan `berlaku_sampai`. | Selesai |
| 3 | Data tipe bisnis, spesialisasi, tahun buka, dan jumlah karyawan toko ada di dalam teks XML. | Diambil dengan `SUBSTRING_INDEX` pada ETL, dicatat di mapping `dim_reseller`. | Selesai |
| 4 | Struktur standar `dim_produk` dari sponsor berbeda dengan usulan v1 dan membuat satu produk punya beberapa baris (SCD tipe 2), sehingga level Produk di cube bisa terhitung dobel. | Kolom disesuaikan dengan standar. Level Produk di cube memakai `produk_id` sebagai key dan nama sebagai caption. Pencarian `produk_key` di ETL memakai `produk_id` dan tanggal pesan. | Selesai |
| 5 | Tiga dimensi (`dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim`) berisi sedikit nilai untuk proses reseller: 10 wilayah (wilayah pesanan sama dengan wilayah toko), 5 dari 105 mata uang terpakai, dan hanya 1 dari 5 metode kirim terpakai. | Tetap dibuat sebagai dimensi conformed karena baris Penjualan Reseller di bus matrix kelas bertanda di ketiganya. Isinya dinyatakan terbuka di `docs/narasi-star-schema.md` bagian 2. Dibuktikan di `sql/uji-dim-wilayah-mata-uang-metode.sql` (60.919 dari 60.919 baris fakta menemukan key). | Selesai |
| 6 | Koneksi Pentaho (PDI 9.2) ke MySQL XAMPP gagal di laptop Anggoro: tombol Database Connection menutup dengan NullPointerException, lalu "Communications link failure" setelah Java diganti. | Penyebab pertama: Pentaho 9.2 butuh Java 8, sedangkan laptop memakai Java 11. Dipasang Temurin 8 dan `Spoon.bat` dijalankan dengan `PENTAHO_JAVA_HOME`. Penyebab kedua: MySQL di XAMPP belum dinyalakan (tombol Start). Koneksi `sumber_adventureworks2` lalu berhasil (Test OK) dan Table input menampilkan `OrderDate` pertama 2011/05/31, dengan Advanced SQL `SET time_zone = '+05:30';`. [Tambahkan kendala dari laptop anggota lain, jika ada] | Selesai  |

## 3. Kendala tim
- Terkait dim_tanggal.sql kemarin yang diberi oleh dosen. terdapat error pada SET SESSION cte_max_recursion_depth = 10000; karena mysql nya saya berapa di mariadb

## 4. Keputusan yang butuh persetujuan sponsor
1. **Strategi SCD.** `dim_sales_person` dan `dim_produk` (biaya dan harga) memakai tipe 2, `dim_reseller`, `dim_promosi`, `dim_wilayah`, `dim_mata_uang`, dan `dim_metode_kirim` tipe 1, `dim_tanggal` tipe 0 (alasan di mapping bagian 2). Mohon persetujuan, karena `dim_sales_person` adalah dimensi conformed dengan proses Kinerja Sales dan strategi SCD-nya perlu disepakati bersama.
2. **Struktur kolom dimensi conformed baru.** `dim_wilayah` (`wilayah_id`, `nama_wilayah`, `kode_negara`, `nama_negara`, `grup_wilayah`), `dim_mata_uang` (`kode_mata_uang`, `nama_mata_uang`), dan `dim_metode_kirim` (`metode_id`, `nama_metode`, `tarif_dasar`, `tarif_per_kg`) mengikuti kolom sumber AdventureWorks. Mohon sponsor mengonfirmasi bahwa struktur ini sama dengan tim lain, supaya penggabungan data antartim memakai dimensi yang sama. Metode pembayaran (4 tipe kartu kredit) tidak dibuat karena tidak ada di bus matrix kelas dan tidak dipakai kelima pertanyaan; bisa diajukan lewat permintaan perubahan.
3. **Struktur `dim_produk`.** Sesuai catatan sponsor, `dim_produk` memakai struktur standar (12 kolom). Mohon sponsor mengonfirmasi bahwa atribut tambahan usulan v1 (ukuran, garis produk, model, harga list, status jual) tidak diperlukan. Bila diperlukan, kami ajukan sebagai tabel tambahan lewat permintaan perubahan (`docs/perubahan/CR-xx.md`), bukan dengan mengubah tabel standar.
4. **Tahun parsial.** Data reseller berawal 31 Mei 2011 dan berakhir 1 Mei 2014. Dashboard menandai 2011 dan 2014 saat membandingkan antartahun.

## 5. Rencana pekan depan
| Target | Penanggung jawab |
|--------|------------------|
| Pasang `dim_tanggal` standar v1.0 | Taufiq Tri W (Data Modeler) |
| Tulis `sql/ddl.sql` (semua dimensi dan fakta, baris -1, foreign key, index) yang bisa dijalankan dua kali | Taufiq Tri W (Data Modeler) |
| Uji constraint dan simpan tangkapan layar error | Zaky (Dashboard Developer) |
| Kamus data semua tabel, termasuk penjelasan `dim_tanggal` | Anggoro Adit H (Project Manager) |
| ERD hasil reverse engineering dari database dan perbandingannya dengan star schema v2 | Chandra Febryan Saputra (OLAP Developer) |
| Daftar tabel staging di dokumen mapping | Riki Audy Bin G (ETL Developer) |
| Laporan pekan 12 | Anggoro Adit H (Project Manager) |

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Anggoro Adit H | Project Manager | Laporan pekan 11, daftar keputusan sponsor, koordinasi koneksi Pentaho |  |
| Taufiq Tri W | Data Modeler | Strategi SCD, star schema v2 (termasuk `dim_produk` standar sponsor) |  |
| Riki Audy Bin G | ETL Developer | Mapping kolom, urutan load, daftar staging, koneksi Pentaho |  |
| Chandra Febryan Saputra | OLAP Developer | Desain cube: hierarki, measure, calculated member | |
| Zaky | Dashboard Developer | Wireframe dashboard |  |
