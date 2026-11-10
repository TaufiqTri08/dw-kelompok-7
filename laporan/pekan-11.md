# Laporan Progres Pekan 11
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau


## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Star Schema Ikuti catatan sponsor dari Steering Review hari ini. Pakai struktur dim_tanggal standar apa adanya. Sesuaikan dim_produk dengan struktur standar.| Selesai | (https://github.com/TaufiqTri08/dw-kelompok-7/blob/c6cd48458c17ddcfd78a9952c2a831c279e8900f/docs/star-schema-v2.png) |
|Source-to-target mapping lengkap Untuk setiap kolom di setiap dimensi dan fakta. Pakai templat di bawah. | Selesai |(https://github.com/TaufiqTri08/dw-kelompok-7/blob/c5a0b306546e918b897e4bb6b01da6c8b029a3f7/docs/mapping.md) |
| Strategi SCD tiap dimensi Tulis tipe yang dipakai untuk kolom-kolom penting beserta alasannya. Minimal satu dimensi memakai tipe 2.  | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/5fd33bdf93d7e630aa0c31de3acb6a06c42f8e9c/docs/mapping.md |
| Urutan load: staging, dimensi, lalu fakta | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/c5a0b306546e918b897e4bb6b01da6c8b029a3f7/docs/mapping.md |
| Desain cube: dimensi, hierarki, measure, calculated member margin | Selesai |https://github.com/TaufiqTri08/dw-kelompok-7/blob/5fd33bdf93d7e630aa0c31de3acb6a06c42f8e9c/docs/desain-cube-dashboard.md |
| Wireframe dashboard untuk kelima pertanyaan bisnis | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/5fd33bdf93d7e630aa0c31de3acb6a06c42f8e9c/docs/Dashboard%20Penjualan%20Reseller%20-%20Wireframe%20v3%20(acuan%20Finnova).png |
| Pentaho terhubung ke database sumber `adventureworks2` (MySQL XAMPP, zona waktu sesi +05:30) di laptop tiap anggota | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/7e9cfe47035b7b538bb25654fdb44edb7303023a/etl/Transformation%201.ktr |


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
1. **Tahun parsial.** Data reseller berawal 31 Mei 2011 dan berakhir 1 Mei 2014. Dashboard menandai 2011 dan 2014 saat membandingkan antartahun.

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
| Taufiq Tri W | Data Modeler | Strategi SCD, star schema v2 (termasuk `dim_produk` standar sponsor) | cc37d0d [https://github.com/TaufiqTri08/dw-kelompok-7/commit/cc37d0d6ca09164f2d17dcc0e3c643c5fc78b746] |
| Riki Audy Bin G | ETL Developer | Mapping kolom, urutan load, daftar staging, koneksi Pentaho |  |
| Chandra Febryan Saputra | OLAP Developer | Desain cube: hierarki, measure, calculated member | |
| Zaky | Dashboard Developer | Wireframe dashboard |  |
