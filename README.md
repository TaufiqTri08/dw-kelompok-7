# dw-kelompok-7: Data Warehouse Penjualan Reseller Adventure Works

Proyek mata kuliah Data Warehouse, pekan 9 sampai 15.
Proses bisnis: **Penjualan Reseller** (pesanan dengan `OnlineOrderFlag = 0`).
Database: **MySQL/MariaDB di XAMPP**, untuk database sumber maupun data warehouse.

## Struktur repositori

```
dw-kelompok-7/
├─ docs/        piagam proyek, pertanyaan bisnis, desain, profil data, bus matrix
├─ sql/         query profil data, query uji pertanyaan bisnis, (nanti) DDL
├─ etl/         file .ktr dan .kjb Pentaho
├─ olap/        schema.xml Mondrian, query MDX
├─ dashboard/   kode web dashboard
└─ laporan/     pekan-10.md ... pekan-14.md
```

## Isi pekan 9 (dilaporkan pekan 10)

| File | Isi |
|------|-----|
| `docs/sumber-data.md` | Asal data (AdventureWorks2017 dari Microsoft), file dump dari dosen, cara import ke XAMPP, dan pemeriksaannya |
| `docs/piagam-proyek.md` | Piagam proyek: latar belakang, 7 pertanyaan bisnis, ruang lingkup, tim, risiko, kriteria sukses |
| `docs/pertanyaan-bisnis.md` | Pertanyaan bisnis beserta fakta, dimensi, dan hasil uji awal |
| `docs/desain-star-schema-v1.md` | Empat langkah desain dimensional, grain, kamus data awal, aturan ETL awal |
| `docs/star-schema-v1.png` | Diagram star schema v1 (`.svg` dan `.dbml` untuk diedit di dbdiagram.io) |
| `docs/bus-matrix.md` | Baris bus matrix tim dan dimensi conformed |
| `docs/profil-data.md` | Hasil profil data sumber dan dampaknya ke desain |
| `docs/hasil-query/` | Hasil acuan kedua file SQL, untuk dicocokkan dengan hasil di laptop |
| `sql/cek-kesiapan.sql` | Satu query untuk memastikan database sumber di laptop setiap anggota sudah benar |
| `sql/profil-data-sumber.sql` | Query profil data sumber (15 bagian) |
| `sql/uji-pertanyaan-bisnis.sql` | Query yang menjawab tiap pertanyaan bisnis langsung dari sumber (pembanding rekonsiliasi) |
| `laporan/pekan-10.md` | Laporan progres untuk Steering Review pekan 10 |

## Menyiapkan database sumber

Sumber data adalah dump MariaDB `adventureworks2` dari dosen (AdventureWorks2017 dari Microsoft, data 2011–2014, rincian di `docs/sumber-data.md`). Dump di-import apa adanya ke MySQL XAMPP. File dump dibagikan ke semua anggota dan **tidak** di-commit ke repositori.

1. Pasang XAMPP, lalu nyalakan **MySQL** dari XAMPP Control Panel.
2. Naikkan batas ukuran paket, karena ada satu perintah di dump yang besarnya sekitar 1 MB. Buka `C:\xampp\mysql\bin\my.ini`, cari `max_allowed_packet` di bagian `[mysqld]`, lalu ubah menjadi:
   ```
   max_allowed_packet=64M
   ```
   Setelah itu klik **Stop** lalu **Start** pada baris MySQL.
3. Klik tombol **Shell** di XAMPP Control Panel, lalu import lewat command line. Ukuran dump 96 MB, melebihi batas upload phpMyAdmin.
   ```
   mysql -u root -e "CREATE DATABASE adventureworks2"
   mysql -u root adventureworks2 < "C:\lokasi\dump-adventureworks2-202509271927.sql"
   ```
4. Cek di phpMyAdmin (`http://localhost/phpmyadmin`), pilih database `adventureworks2`, buka tab **SQL**:
   ```sql
   SELECT COUNT(*) FROM sales_salesorderheader;
   ```
   Hasilnya harus **31465**.
5. Jangan ubah isi database ini. Database sumber hanya dibaca.

## Menjalankan query profil

**Selalu jalankan `SET time_zone = '+05:30';` lebih dulu di setiap sesi.** Alasannya dijelaskan di `docs/sumber-data.md` bagian 3 dan di bagian 0 `sql/profil-data-sumber.sql`.

- **phpMyAdmin**: pilih `adventureworks2`, buka tab **SQL**, tempel baris `SET time_zone` lalu satu bagian query, kemudian klik **Go**.
- **HeidiSQL** atau **DBeaver** (keduanya gratis, diunduh terpisah): sambungkan ke `localhost`, port 3306, user `root`, buka file SQL, lalu jalankan per bagian. Di DBeaver, **Alt+X** menjalankan semua query, dan setiap hasil muncul di tab terpisah.
- **Command line** (semua sekaligus, hasil disimpan ke file teks):
  ```
  mysql -u root -t adventureworks2 < sql\profil-data-sumber.sql > hasil-profil.txt
  mysql -u root -t adventureworks2 < sql\uji-pertanyaan-bisnis.sql > hasil-uji.txt
  ```

Hasil bagian 1 dan 15 dari `profil-data-sumber.sql` harus sama di laptop semua anggota:
3.806 pesanan reseller, 60.919 baris detail, total nilai USD 80.487.704,18. Hasil lengkapnya ada di `docs/hasil-query/`.
