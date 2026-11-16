# Laporan Progres Pekan 12
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau



## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| 1. Pasang `dim_tanggal` standar versi 1.0. Simpan hasil query pemeriksaan. | Selesai |(https://github.com/TaufiqTri08/dw-kelompok-7/blob/5395ffa02924b075982bec7ce060f3dde8d6d2a3/sql/dim_tanggal_mysql.sql) |
| 2. Tulis `sql/ddl.sql`: semua dimensi dan fakta tim, termasuk baris -1, foreign key, dan index. Harus bisa dijalankan dua kali berturut-turut tanpa error. | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/5395ffa02924b075982bec7ce060f3dde8d6d2a3/sql/ddl.sql |
| 3. Uji constraint: jalankan tiga uji di tab Uji Constraint. Simpan tangkapan layar pesan error. | Selesai | commit |
| 4. Kamus data di `docs/kamus-data.md`: semua tabel DW, termasuk penjelasan `dim_tanggal` dengan bahasa sendiri dan versi skrip yang dipakai. | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/5395ffa02924b075982bec7ce060f3dde8d6d2a3/docs/kamus-data.md |
| 5. ERD dari database: buat dengan reverse engineering dari database yang sudah jadi (DBeaver), bandingkan dengan star schema v2. Harus sama. | Selesai | commit |
| 6. Daftar tabel staging, ditambahkan di dokumen mapping. | Selesai | https://github.com/TaufiqTri08/dw-kelompok7/blob/5395ffa02924b075982bec7ce060f3dde8d6d2a3/docs/mapping.md |
| 7. Laporan pekan 12 memakai templat laporan progres. Sertakan permintaan perubahan jika ada. | Selesai | https://github.com/TaufiqTri08/dw-kelompok-7/blob/5395ffa02924b075982bec7ce060f3dde8d6d2a3/laporan/pekan-12.md |



## 2. Kendala pengerjaan
1. Skrip tanggal standar dari dosen tidak bisa langsung dijalankan di server database laptop kami karena versinya berbeda. 

2. Terkait Satu nama kolom salah satuan (kilogram, padahal per pound) sudah diperbaiki

## 3. Kendala tim
Koordinasi antar anggota tim berjalan walaupun kesulitan untuk meyelaraskan ide dan keep up dalam pengerjaan.

## 4. Keputusan yang butuh persetujuan sponsor
**Nama kolom `tarif_per_lb` pada `dim_metode_kirim`** . Di sumber `ShipRate` berarti tarif per pound, jadi nama `tarif_per_kg` yang dipakai di v1 dan di laporan pekan 11 



## 5. Rencana pekan depan
| Target | Penanggung jawab |
|--------|------------------|
| Buat tabel staging lewat Pentaho dan salin data dari `adventureworks2` (koneksi sumber dengan zona waktu sesi +05:30) | Anggoro Adit Haptono  |
| Transformasi dan load dimensi tipe 1 | Riki Audy Bin G (ETL Developer) |
| Transformasi `dim_sales_person` tipe 2 dari riwayat wilayah | Riki Audy Bin G (ETL Developer) |
| Transformasi dan load fakta beserta pencarian key | Riki Audy Bin G (ETL Developer) |
| Rekonsiliasi: 60.919 baris, 3.806 pesanan, USD 80.487.704,18, margin USD 476.896,95 | Taufiq Tri W (Data Modeler) |
| Siapkan skema Mondrian dari `docs/desain-cube-dashboard.md` | Chandra Febryan Saputra (OLAP Developer) |
| Siapkan kerangka web dashboard dari wireframe | Muhammad Zakky Ulil Amry (Dashboard Developer) |

## 6. Kontribusi anggota
| Nama | Peran | Yang dikerjakan pekan ini | Bukti commit |
|------|-------|---------------------------|--------------|
| Anggoro Adit H | Project Manager | Kamus data, laporan pekan 12 | [6583579](https://github.com/TaufiqTri08/dw-kelompok-7/commit/6583579f9a48174800be87950049d81ea3fa7b1f) |
| Taufiq Tri W | Data Modeler | Pasang `dim_tanggal`, `ddl.sql`, bukti dua kali jalan | [5395ffa](https://github.com/TaufiqTri08/dw-kelompok-7/commit/5395ffa02924b075982bec7ce060f3dde8d6d2a3) |
| Riki Audy Bin G | ETL Developer | Daftar staging, cek tipe data DDL terhadap sumber | [543a1b1](https://github.com/TaufiqTri08/dw-kelompok-7/commit/543a1b1b25e04cae3a342570c195a4137a59030c) |
| Chandra Febryan Saputra | OLAP Developer | ERD dari database dan perbandingan dengan v2 | Commit |
| Muhammad Zakky Ulil Amry | Dashboard Developer | Uji constraint, tangkapan layar error uji 1 sampai 3 | Commit |
