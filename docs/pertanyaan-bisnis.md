# Pertanyaan Bisnis: Penjualan Reseller

Kelompok      : 7
Proses bisnis : Penjualan Reseller
Status        : Usulan untuk Steering Review pekan 10

Urutan kerja yang kami pakai: **tanya**, lalu **pecah** menjadi fakta dan dimensi, lalu **lacak** ke tabel sumber.
Setiap pertanyaan sudah diuji langsung ke database sumber dengan query di `sql/uji-pertanyaan-bisnis.sql`.

## Daftar pertanyaan

| No | Pertanyaan bisnis | Fakta (ukuran) | Dimensi (sudut pandang) |
|----|-------------------|----------------|-------------------------|
| P1 | Kategori dan subkategori produk apa yang nilai penjualan resellernya tumbuh paling cepat dari kuartal ke kuartal? | `nilai_penjualan` | Produk (kategori, subkategori), Tanggal pesan (tahun, kuartal) |
| P2 | Sales person mana yang menghasilkan nilai penjualan dan margin kotor terbesar setiap tahun, dan berapa jumlah pesanannya? | `nilai_penjualan`, `total_biaya_produk` (margin kotor = nilai penjualan − total biaya), jumlah pesanan = `COUNT(DISTINCT nomor_pesanan)` | Sales Person (nama, jabatan), Tanggal pesan (tahun) |
| P3 | Wilayah dan grup wilayah mana yang memberi nilai penjualan reseller terbesar, dan bagaimana trennya per tahun? | `nilai_penjualan`, `jumlah_unit` | Wilayah (grup wilayah, negara, wilayah), Tanggal pesan (tahun) |
| P4 | Jenis promosi mana yang memberi nilai diskon terbesar, untuk kategori produk apa, dan berapa unit yang terjual dengan promosi itu? | `nilai_diskon`, `jumlah_unit` | Promosi (jenis, nama promosi), Produk (kategori) |
| P5 | Siapa 10 reseller dengan nilai penjualan terbesar, dan tipe bisnis reseller mana yang kontribusinya paling besar per tahun? | `nilai_penjualan`, jumlah pesanan | Reseller (nama, tipe bisnis), Tanggal pesan (tahun) |
| P6 | Produk dan kategori mana yang dijual ke reseller di bawah biaya standarnya, dan berapa total margin negatifnya per tahun? | `nilai_penjualan`, `total_biaya_produk` | Produk (kategori, nama produk), Tanggal pesan (tahun) |
| P7 | Berapa porsi nilai penjualan reseller yang ditransaksikan dalam mata uang selain USD di tiap wilayah? | `nilai_penjualan` | Mata Uang (kode), Wilayah (negara, wilayah) |

Catatan:

- Margin kotor dan persentase tidak disimpan di tabel fakta. Keduanya dihitung saat ditampilkan (calculated member di cube atau rumus di dashboard), karena persentase bersifat non-aditif.
- Jumlah pesanan dihitung dari dimensi degeneratif `nomor_pesanan`, bukan disimpan sebagai fakta, karena grain kita per baris pesanan.
- Semua nilai uang dalam USD. Di data sumber, harga sudah dalam USD walaupun mata uang transaksinya berbeda.

## Hasil uji awal ke data sumber

Angka dari database `adventureworks2` (MySQL XAMPP) yang kami pakai (data 31 Mei 2011 sampai 1 Mei 2014). Ini bukti bahwa tiap pertanyaan bisa diukur, bukan hasil akhir.

| No | Temuan awal |
|----|-------------|
| P1 | Kategori Bikes menyumbang 82,4% nilai penjualan reseller (USD 66,3 juta dari USD 80,5 juta). |
| P2 | Sales person dengan nilai penjualan terbesar berganti tiap tahun: Tsvi Reiter (2011), Jillian Carson (2012), Linda Mitchell (2013), Jae Pak (2014, data sampai 1 Mei). |
| P3 | Tiga wilayah terbesar: Southwest (USD 18,5 juta), Canada (USD 14,4 juta), Northwest (USD 12,4 juta). |
| P4 | Diskon terbesar datang dari promosi New Product (USD 223.552), lalu Discontinued Product (USD 152.381) dan Volume Discount (USD 127.718). |
| P5 | Reseller terbesar adalah Brakes and Gears (USD 877.107). Tipe bisnis Warehouse menjadi penyumbang terbesar di setiap tahun. |
| P6 | Margin kotor reseller hanya 0,59% secara keseluruhan dan negatif di 2013 (−USD 274.358) serta 2014 (−USD 27.993). Kategori Bikes bermargin −1,49%. Ada 21.829 baris pesanan yang dijual di bawah biaya standar. |
| P7 | 28,3% nilai penjualan reseller ditransaksikan dalam mata uang selain USD (CAD, GBP, EUR, AUD). |

Temuan P6 kami usulkan menjadi fokus utama dashboard karena paling relevan untuk keputusan manajemen.
