# Bukti untuk Steering Review

Folder ini menyimpan tangkapan layar yang dibuktikan saat Steering Review.
Berkas gambar **tidak** dibuat otomatis; setiap anggota mengambil tangkapan
layar dari laptop masing-masing lalu menyimpannya di sini.

## Aturan nama berkas

`<jenis>-<nama>.png`, huruf kecil, tanpa spasi. Contoh:
`kesiapan-taufiq.png`, `pentaho-anggoro.png`.

## Daftar bukti

| Jenis | Isi tangkapan layar | Diperlukan sejak |
|-------|---------------------|------------------|
| `kesiapan-<nama>` | Hasil `sql/cek-kesiapan.sql` di database `adventureworks2`: 71 tabel, 31.465 pesanan, 3.806 pesanan reseller, 60.919 baris detail, subtotal 80.487.704,18 | Pekan 10 |
| `pentaho-<nama>` | Spoon terbuka, koneksi `sumber_adventureworks2` Test OK, Table input menampilkan `OrderDate` pertama `2011-05-31` | Pekan 10 |
| `ddl-<nama>` | `SHOW TABLES` di `dw_kelompok_7` setelah `sql/ddl.sql` dijalankan | Pekan 11 |
| `constraint-<nama>` | Pesan error saat uji foreign key/unique/NOT NULL di `sql/uji-constraint.sql` | Pekan 11 |

## Cara mengecek kelengkapan

1. Buka folder ini di GitHub; jumlah gambar harus sama dengan jumlah anggota
   untuk setiap jenis bukti yang sudah jatuh tempo.
2. Cocokkan angka di tangkapan layar dengan kolom `acuan` pada
   `sql/cek-kesiapan.sql`.
3. Kalau ada anggota yang belum mengunggah, catat sebagai kendala tim di laporan
   pekan berjalan, jangan diisi sendiri.
