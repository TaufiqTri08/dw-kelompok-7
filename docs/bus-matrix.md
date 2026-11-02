# Bus Matrix: Baris Kelompok X (Penjualan Reseller)

● = dimensi dipakai oleh proses ini
**C** = conformed dimension (dipakai lebih dari satu proses, strukturnya harus sama di semua tim)

## Baris tim kami

| Proses bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim | Sales Person | Reseller | Vendor | Karyawan | Alasan Scrap | Jenis Transaksi | Alasan Penjualan |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Penjualan Reseller** | ● C | ● C | | ● C | ● C | ● C | ● C | ● C | ● | | | | | |

Total: 8 dimensi, 7 di antaranya conformed. Hanya `dim_reseller` yang khusus milik proses ini, sehingga tim kami bebas merancang strukturnya.

## Dimensi conformed yang kami pakai dan tim yang perlu diajak sepakat

| Dimensi | Dipakai oleh | Yang perlu disepakati |
|---------|--------------|-----------------------|
| `dim_tanggal` | Semua proses (7) | Mengikuti standar dari sponsor |
| `dim_produk` | Penjualan Online, Penjualan Reseller, Pembelian, Produksi, Pergerakan Persediaan | Nama kolom, hierarki kategori, surrogate key (ditetapkan pekan 10) |
| `dim_wilayah` | Penjualan Online, Penjualan Reseller, Kinerja Sales, Alasan Pembelian | Kolom grup wilayah dan negara |
| `dim_metode_kirim` | Penjualan Online, Penjualan Reseller, Pembelian | Kolom tarif |
| `dim_promosi` | Penjualan Online, Penjualan Reseller | Kolom jenis dan kategori promosi |
| `dim_mata_uang` | Penjualan Online, Penjualan Reseller | Kode ISO 3 huruf sebagai natural key |
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

Catatan: profil data menunjukkan semua pesanan reseller memakai satu metode kirim (CARGO TRANSPORT 5). `dim_metode_kirim` tetap dipakai karena conformed dan akan bermakna saat hasil semua tim digabung.
