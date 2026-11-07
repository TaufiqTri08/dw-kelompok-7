# Bus Matrix: Baris Kelompok 7 (Penjualan Reseller)

● = dimensi dipakai oleh proses ini
◐ = tidak punya tabel dimensi sendiri, tetapi atributnya ada di dimensi lain atau di tabel fakta (nama dan isi kolom sama dengan dimensi tim lain)
**C** = conformed dimension (dipakai lebih dari satu proses, strukturnya harus sama di semua tim)

## Baris tim kami

| Proses bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim | Sales Person | Reseller | Vendor | Karyawan | Alasan Scrap | Jenis Transaksi | Alasan Penjualan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Penjualan Reseller** | ● C | ● C | | ◐ | ● C | ◐ | | ● C | ● | | | | | |

Total: 5 dimensi, 4 di antaranya conformed (Tanggal, Produk, Promosi, Sales Person). Hanya `dim_reseller` yang khusus milik proses ini, sehingga tim kami bebas merancang strukturnya.

Tiga kolom pada matriks kelas yang tidak punya tabel dimensi sendiri di desain kami:

- **Wilayah**: atribut `nama_wilayah`, `negara_wilayah`, `grup_wilayah` ada di `dim_reseller`, karena wilayah pesanan selalu sama dengan wilayah toko (3.806 dari 3.806 pesanan).
- **Mata Uang**: kolom `kode_mata_uang` di fakta (5 nilai).
- **Metode Kirim**: tidak dipakai, karena semua pesanan reseller memakai satu metode (CARGO TRANSPORT 5).

## Dimensi conformed yang kami pakai dan tim yang perlu diajak sepakat

| Dimensi | Dipakai oleh | Yang perlu disepakati |
|---------|--------------|-----------------------|
| `dim_tanggal` | Semua proses (7) | Mengikuti standar dari sponsor |
| `dim_produk` | Penjualan Online, Penjualan Reseller, Pembelian, Produksi, Pergerakan Persediaan | Struktur standar dari sponsor (pekan 10): 12 kolom dengan `biaya_standar` dan `harga_jual` SCD tipe 2. Hierarki kategori, surrogate key |
| `dim_promosi` | Penjualan Online, Penjualan Reseller | Kolom jenis dan kategori promosi |
| `dim_sales_person` | Penjualan Reseller, Kinerja Sales | Strategi SCD untuk wilayah tugas |

## Bus matrix kelas (rujukan dari halaman Pertemuan 9)

| Proses bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim | Sales Person | Reseller | Vendor | Karyawan | Alasan Scrap | Jenis Transaksi | Alasan Penjualan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Penjualan Online | ● | ● | ● | ● | ● | ● | ● | | | | | | | |
| **Penjualan Reseller** | ● | ● | | ● | ● | ● | ● | ● | ● | | | | | |
| Kinerja Sales vs Target | ● | | | ● | | | | ● | | | | | | |
| Pembelian | ● | ● | | | | | ● | | | ● | ● | | | |
| Produksi | ● | ● | | | | | | | | | | ● | | |
| Pergerakan Persediaan | ● | ● | | | | | | | | | | | ● | |
| Alasan Pembelian Pelanggan | ● | | ● | ● | | | | | | | | | | ● |
| **Jumlah proses** | 7 | 5 | 2 | 4 | 2 | 2 | 3 | 2 | 1 | 1 | 1 | 1 | 1 | 1 |

Catatan penggabungan antar-tim: tim lain tetap memakai `dim_wilayah`, `dim_mata_uang`, dan `dim_metode_kirim`. Drill-across ke Penjualan Online dan Kinerja Sales tetap bisa dilakukan lewat atribut yang namanya dan isinya sama: `nama_wilayah`, `negara_wilayah`, `grup_wilayah` (di `dim_reseller`) dan `kode_mata_uang` (di fakta, memakai kode ISO yang sama). Hal ini perlu disetujui sponsor (lihat laporan pekan 10, keputusan nomor 6).
