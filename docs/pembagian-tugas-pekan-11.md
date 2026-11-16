# Pembagian Tugas Pekan 11

Kelompok : 7
Proses   : Penjualan Reseller
Acuan    : `laporan/pekan-11.md` bagian 5, `docs/mapping.md`, `docs/kamus-data.md`
Dilaporkan: Steering Review pekan 12 (`laporan/pekan-12.md`)

Materi pekan 11 adalah **implementasi desain di RDBMS**: memasang DDL, menguji
constraint, dan menyiapkan bukti bahwa desain v2 benar-benar bisa dijalankan.
Peran berarti penanggung jawab; semua anggota tetap ikut memeriksa hasil.

## 1. Daftar tugas

| No | Tugas | Penanggung jawab | Bukti yang harus ada |
|----|-------|------------------|----------------------|
| 1 | Pasang `dim_tanggal` standar sponsor v1.0 (`sql/dim_tanggal_mysql.sql`) di database `dw_kelompok_7` | Taufiq Tri W (Data Modeler) | Tangkapan layar `SELECT COUNT(*)` = 2.192 baris dan baris `tanggal_key = -1` |
| 2 | Jalankan `sql/ddl.sql` (8 dimensi + 1 fakta, baris -1, foreign key, index) dan pastikan bisa dijalankan dua kali tanpa error | Taufiq Tri W (Data Modeler) | Tangkapan layar hasil run pertama dan kedua, daftar tabel `SHOW TABLES` |
| 3 | Uji constraint: foreign key, unique, NOT NULL, dan primary key fakta | Muhammad Zakky Ulil Amry (Dashboard Developer) | Tangkapan layar pesan error tiap uji di `docs/bukti/`, dicatat di laporan |
| 4 | ERD hasil reverse engineering dari database dan perbandingannya dengan star schema v2 | Chandra Febryan Saputra (OLAP Developer) | Gambar ERD + catatan perbedaan (harus tidak ada perbedaan struktur) |
| 5 | Lengkapi daftar tabel staging dan urutan load di `docs/mapping.md` | Riki Audy Bin G (ETL Developer) | Bagian 3 dan 4 `docs/mapping.md` sudah final |
| 6 | Periksa ulang `docs/kamus-data.md` terhadap `sql/ddl.sql` (nama kolom, tipe, panjang) | Taufiq Tri W | Kamus data tidak menyebut kolom yang tidak ada di DDL |
| 7 | Kumpulkan bukti kesiapan database 5 anggota dan tangkapan layar uji Pentaho | Anggoro Adit H (Project Manager) | `docs/bukti/kesiapan-<nama>.png` dan `docs/bukti/pentaho-<nama>.png` |
| 8 | Tulis `laporan/pekan-12.md` | Anggoro Adit H (Project Manager) | Laporan dengan status dan tautan commit |

## 2. Aturan kerja

1. Satu tugas satu commit. Pesan commit menyebut nomor tugas, misalnya
   `#2 ddl: tambah index fakta`.
2. Setiap anggota yang menyentuh file orang lain harus minta review pemilik
   tugas lewat Pull Request atau komentar commit.
3. Tangkapan layar disimpan dengan nama `docs/bukti/<jenis>-<nama>.png`, huruf
   kecil, tanpa spasi. Daftar jenis ada di `docs/bukti/README.md`.
4. Angka acuan tidak boleh diubah. Kalau hasil berbeda, periksa dulu
   `docs/catatan-sql.md` sebelum menyimpulkan DDL salah.
5. Desain dikunci setelah disetujui sponsor di pekan 11. Perubahan setelah itu
   memakai catatan perubahan di `docs/perubahan/CR-xx.md`.

## 3. Definition of done pekan 11

- `sql/ddl.sql` berhasil dijalankan dua kali berturut-turut di database kosong.
- Semua tabel dan baris -1 ada: 9 tabel (8 dimensi + 1 fakta), `dim_tanggal`
  2.192 baris, 8 baris -1 di dimensi lain.
- Uji constraint menghasilkan error sesuai harapan, bukan error sintaks.
- ERD hasil reverse engineering sama dengan `docs/star-schema-v2.dbml`.
- `laporan/pekan-12.md` terisi dan semua baris target berstatus Selesai.
