# Bus Matrix: Baris Kelompok X (Penjualan Reseller)

● = dimensi dipakai oleh proses ini
**C** = conformed dimension (dipakai lebih dari satu proses, strukturnya harus sama di semua tim)

## Baris tim kami

| Proses bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim | Sales Person | Reseller | Vendor | Karyawan | Alasan Scrap | Jenis Transaksi | Alasan Penjualan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Penjualan Reseller** | ● C | ● C | | ● C | ● C | ● C | ● C | ● C | ● | | | | | |

Total: 8 dimensi, 7 di antaranya conformed (Tanggal, Produk, Wilayah, Promosi, Mata Uang, Metode Kirim, Sales Person). Hanya `dim_reseller` yang khusus milik proses ini, sehingga tim kami bebas merancang strukturnya. Baris ini sama dengan baris Penjualan Reseller di bus matrix kelas (bagian bawah).

Kolom Pelanggan tidak dipakai karena pembeli di proses ini adalah toko. Kolom Vendor, Karyawan, Alasan Scrap, Jenis Transaksi, dan Alasan Penjualan milik proses lain.

## Dimensi conformed yang kami pakai dan tim yang perlu diajak sepakat

| Dimensi | Dipakai oleh | Yang perlu disepakati |
|---------|--------------|-----------------------|
| `dim_tanggal` | Semua proses (7) | Mengikuti standar dari sponsor |
| `dim_produk` | Penjualan Online, Penjualan Reseller, Pembelian, Produksi, Pergerakan Persediaan | Struktur standar dari sponsor (pekan 10): 12 kolom dengan `biaya_standar` dan `harga_jual` SCD tipe 2. Hierarki kategori, surrogate key |
| `dim_promosi` | Penjualan Online, Penjualan Reseller | Kolom jenis dan kategori promosi |
| `dim_sales_person` | Penjualan Reseller, Kinerja Sales | Strategi SCD untuk wilayah tugas |
| `dim_wilayah` | Penjualan Online, Penjualan Reseller, Kinerja Sales, Alasan Pembelian Pelanggan | Kolom: `wilayah_id`, `nama_wilayah`, `kode_negara`, `nama_negara`, `grup_wilayah` |
| `dim_mata_uang` | Penjualan Online, Penjualan Reseller | Kolom: `kode_mata_uang` (kode ISO), `nama_mata_uang` |
| `dim_metode_kirim` | Penjualan Online, Penjualan Reseller, Pembelian | Kolom: `metode_id`, `nama_metode`, `tarif_dasar`, `tarif_per_kg` |

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

Catatan penggabungan antar-tim: karena Wilayah, Mata Uang, dan Metode Kirim kami buat sebagai dimensi sendiri, drill-across ke Penjualan Online dan Kinerja Sales memakai key dimensi yang sama. Struktur kolom ketiganya (tabel di atas) perlu disepakati dengan tim lain; usulan kami mengikuti kolom sumber AdventureWorks.
