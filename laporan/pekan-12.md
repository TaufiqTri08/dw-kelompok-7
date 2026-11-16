# Laporan Progres Pekan 12
Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Hijau



## 1. Target dan capaian
| Target pekan ini | Status | Bukti (tautan file, commit, tangkapan layar) |
|------------------|--------|-----------------------------------------------|
| 1. Pasang `dim_tanggal` standar versi 1.0. Simpan hasil query pemeriksaan. | Selesai | `docs/bukti/dim-tanggal-pemeriksaan.png` (2.192 baris, 2010-01-01 sampai 2015-12-31, 20130315 hari Jumat). Skrip: `sql/dim_tanggal_mysql.sql` (untuk MariaDB: `sql/dim_tanggal_alternatif.sql`) |
| 2. Tulis `sql/ddl.sql`: semua dimensi dan fakta tim, termasuk baris -1, foreign key, dan index. Harus bisa dijalankan dua kali berturut-turut tanpa error. | Selesai | `sql/ddl.sql` (7 dimensi + 1 fakta, baris -1, 10 foreign key, 10 index, 5 CHECK; `dim_tanggal` dipasang dari skrip standar sponsor, jadi DW berisi 9 tabel). Bukti dua kali jalan: `docs/bukti/ddl-jalan-dua-kali.png` |
| 3. Uji constraint: jalankan tiga uji di tab Uji Constraint. Simpan tangkapan layar pesan error. | Selesai | `docs/bukti/uji-1.png`, `uji-2.png`, `uji-3.png` dari `sql/uji-constraint.sql` (uji 4 sampai 12 tambahan tim) |
| 4. Kamus data di `docs/kamus-data.md`: semua tabel DW, termasuk penjelasan `dim_tanggal` dengan bahasa sendiri dan versi skrip yang dipakai. | Selesai | `docs/kamus-data.md` (9 tabel, 12 kolom `dim_tanggal`, skrip `dim_tanggal_mysql.sql` versi 1.0, dan tiga jawaban catatan dari halaman tugas) |
| 5. ERD dari database: buat dengan reverse engineering dari database yang sudah jadi (DBeaver), bandingkan dengan star schema v2. Harus sama. | Selesai | `docs/bukti/erd-database.png`, dibandingkan dengan `docs/star-schema-v2.png` (8 dimensi, 10 garis relasi) |
| 6. Daftar tabel staging, ditambahkan di dokumen mapping. | Selesai | `docs/mapping.md` bagian 4 (22 tabel staging) |
| 7. Laporan pekan 12 memakai templat laporan progres. Sertakan permintaan perubahan jika ada. | Selesai | `laporan/pekan-12.md`. Permintaan perubahan: `docs/perubahan/CR-01.md` (menunggu keputusan sponsor) |



## 2. Kendala pengerjaan
1. Skrip tanggal standar dari dosen tidak bisa langsung dijalankan di server database laptop kami karena versinya berbeda. 

2. Terkait Satu nama kolom salah satuan (kilogram, padahal per pound) sudah diperbaiki

## 3. Kendala tim
Koordinasi antar anggota tim berjalan walaupun kesulitan untuk meyelaraskan ide dan keep up dalam pengerjaan.

## 4. Keputusan yang butuh persetujuan sponsor
1. **`dim_tanggal` hanya memakai skrip standar v1.0 (12 kolom).** Tidak ada atribut tambahan. Jika dibutuhkan (misalnya hari libur), dibuat tabel terpisah yang terhubung lewat `tanggal_key`.
2. **Nilai pengganti -1 untuk atribut angka yang kosong** (`qty_maks`, `tahun_buka`, `jumlah_karyawan`) supaya kolom tetap `NOT NULL`.
3. **Ongkos kirim dan pajak tetap di luar lingkup v1** (usulan dari laporan pekan 10 belum berubah).
4. **Ukuran uang** `DECIMAL(14,4)` di fakta dan `DECIMAL(12,4)` di dimensi, sesuai ketelitian 4 desimal di sumber.
5. **Nama kolom `tarif_per_lb` pada `dim_metode_kirim`** . Di sumber `ShipRate` berarti tarif per pound, jadi nama `tarif_per_kg` yang dipakai di v1 dan di laporan pekan 11 



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
| Anggoro Adit H | Project Manager | Kamus data, laporan pekan 12 | Commit |
| Taufiq Tri W | Data Modeler | Pasang `dim_tanggal`, `ddl.sql`, bukti dua kali jalan | Commit |
| Riki Audy Bin G | ETL Developer | Daftar staging, cek tipe data DDL terhadap sumber | Commit |
| Chandra Febryan Saputra | OLAP Developer | ERD dari database dan perbandingan dengan v2 | Commit |
| Muhammad Zakky Ulil Amry | Dashboard Developer | Uji constraint, tangkapan layar error uji 1 sampai 3 | Commit |
