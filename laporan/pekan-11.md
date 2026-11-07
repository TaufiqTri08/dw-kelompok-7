# Laporan Progres Pekan 11
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : [Hijau / Kuning / Merah]

> Laporan hasil pekan 10 (desain ETL, cube, dan dashboard) untuk Steering Review pekan 11. Pilih **Hijau** hanya jika semua baris di tabel 1 berstatus Selesai, termasuk koneksi Pentaho di laptop tiap anggota. Hapus catatan ini sebelum dikirim.

## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| Source-to-target mapping untuk setiap kolom dimensi dan fakta | Selesai | `docs/mapping.md` bagian 1 |
| Strategi SCD tiap dimensi (tipe 0, 1, atau 2) beserta alasannya | Selesai | `docs/mapping.md` bagian 2 |
| Urutan load: staging, dimensi, lalu fakta | Selesai | `docs/mapping.md` bagian 3 |
| Desain cube: dimensi, hierarki, measure, calculated member margin | Selesai | `docs/desain-cube-dashboard.md` bagian 1 |
| Wireframe dashboard untuk kelima pertanyaan bisnis | Selesai | `docs/wireframe-dashboard.png`, rincian panel di `docs/desain-cube-dashboard.md` bagian 2 |
| Star schema versi 2 | Belum | `docs/star-schema-v2.png`, `docs/star-schema-v2.dbml`, `docs/narasi-star-schema.md` |
| Pentaho terhubung ke database sumber `adventureworks2` (MySQL XAMPP, zona waktu sesi +05:30) di laptop tiap anggota | [Selesai / x dari 5 anggota] | `docs/bukti/pentaho-koneksi-<nama>.png` (tombol Test pada koneksi) |

Perubahan dari star schema v1 ke v2:


Angka kunci:

- Mapping mencakup 5 dimensi dan 1 fakta (60.919 baris), ditulis dengan templat mapping dari dosen. `dim_sales_person` berisi 20 versi dari 17 sales person, dan `dim_produk` 606 versi dari 504 produk.
- Urutan load: dim_tanggal dan DDL, staging, dimensi tipe 1, dimensi tipe 2 (`dim_produk`, `dim_sales_person`), fakta, rekonsiliasi.
- Angka rekonsiliasi untuk ETL: 60.919 baris fakta, 3.806 pesanan, nilai penjualan USD 80.487.704,18, margin kotor USD 476.896,95.
- Cube: 7 measure (termasuk jumlah pesanan dengan distinct-count dan harga satuan dengan avg) dan 4 calculated member.
- Daftar tabel staging: 20 tabel.

## 2. Kendala pengerjaan
| No | Kendala | Yang sudah dicoba | Status |
|----|---------|-------------------|--------|
| 1 | Satu sales person bisa muncul beberapa kali di dimensi (SCD tipe 2), sehingga di cube level Sales Person bisa terhitung dobel. | Level Sales Person di cube memakai `sales_person_id` sebagai key dan nama sebagai caption, sehingga total per orang menyatu walaupun pindah wilayah. | Selesai |
| 2 | Pencarian `sales_person_key` di ETL harus memakai tanggal pesan, bukan hanya `SalesPersonID`. | Aturan pencarian ditulis di mapping fakta: `SalesPersonID` sama dan tanggal pesan di antara `berlaku_mulai` dan `berlaku_sampai`. | Selesai |
| 3 | Data tipe bisnis, spesialisasi, tahun buka, dan jumlah karyawan toko ada di dalam teks XML. | Diambil dengan `SUBSTRING_INDEX` pada ETL, dicatat di mapping `dim_reseller`. | Selesai |
| 4 | Struktur standar `dim_produk` dari sponsor berbeda dengan usulan v1 dan membuat satu produk punya beberapa baris (SCD tipe 2), sehingga level Produk di cube bisa terhitung dobel. | Kolom disesuaikan dengan standar. Level Produk di cube memakai `produk_id` sebagai key dan nama sebagai caption. Pencarian `produk_key` di ETL memakai `produk_id` dan tanggal pesan. | Selesai |
| 5 | 64 baris pesanan (25 produk) jatuh setelah periode biaya terakhir di sumber (periode terakhir 98 produk sudah ditutup paling lambat 2013-05-29), sehingga tidak menemukan versi produk. | Periode terakhir diperpanjang sampai 9999-12-31, karena biaya dan harga di `production.product` sama persis dengan periode terakhir itu (98 dari 98 produk). Dibuktikan lewat `sql/uji-dim-produk-scd2.sql`: 60.919 baris menemukan tepat satu versi, margin tetap USD 476.896,95. | Selesai |
| 6 | [Tambahkan kendala koneksi Pentaho ke MySQL XAMPP dari laptop anggota, misalnya driver JDBC, zona waktu, atau versi Java (Pentaho 9.2 butuh Java 8).] | [Yang sudah dicoba] | [Selesai / Masih] |

## 3. Kendala tim
- 

## 4. Keputusan yang butuh persetujuan sponsor
1. **Strategi SCD.** `dim_sales_person` dan `dim_produk` (biaya dan harga) memakai tipe 2, `dim_reseller` dan `dim_promosi` tipe 1, `dim_tanggal` tipe 0 (alasan di mapping bagian 2). Mohon persetujuan, karena `dim_sales_person` adalah dimensi conformed dengan proses Kinerja Sales dan strategi SCD-nya perlu disepakati bersama.
2. **Tindak lanjut keputusan nomor 6 laporan pekan 10.** Metode kirim, wilayah, dan mata uang tidak punya dimensi sendiri. Mohon sponsor mengonfirmasi bahwa penggabungan dengan tim lain memakai atribut `nama_wilayah`, `negara_wilayah`, `grup_wilayah` (di `dim_reseller`) dan `kode_mata_uang` (di fakta).
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
| Anggoro Adit H | Project Manager | Laporan pekan 11, daftar keputusan sponsor, koordinasi koneksi Pentaho | [hash commit] |
| Taufiq Tri W | Data Modeler | Strategi SCD, star schema v2 (termasuk `dim_produk` standar sponsor) | [hash commit] |
| Riki Audy Bin G | ETL Developer | Mapping kolom, urutan load, daftar staging, koneksi Pentaho | [hash commit] |
| Chandra Febryan Saputra | OLAP Developer | Desain cube: hierarki, measure, calculated member | [hash commit] |
| Zaky | Dashboard Developer | Wireframe dashboard | [hash commit] |
