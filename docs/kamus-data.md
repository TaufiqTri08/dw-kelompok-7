# Kamus Data Data Warehouse Penjualan Reseller

Kelompok : X
Database : `dw_kelompok_x` (MySQL/MariaDB XAMPP, mesin InnoDB)
Skrip    : `sql/ddl.sql` (star schema v2, 5 dimensi), `dim_tanggal` dari skrip standar sponsor v1.0 (isi versi yang dipakai: `dim_tanggal_mysql.sql` v____)
Rincian sumber tiap kolom: `docs/mapping.md`

Aturan yang berlaku di semua tabel:

- **Surrogate key** (`..._key`) berupa `INT AUTO_INCREMENT`, dibuat oleh DW. **Natural key** (`..._id`) adalah key asli dari sumber.
- **Baris -1 "Tidak diketahui"** ada di setiap dimensi. Key kosong di fakta diisi -1, bukan NULL.
- **Uang** memakai `DECIMAL(14,4)` di fakta dan `DECIMAL(12,4)` di dimensi, sesuai ketelitian 4 desimal di sumber. Semua nilai dalam USD.
- Kolom `VARCHAR` mengikuti panjang kolom di sumber, kecuali dicatat lain.

---

## `fact_penjualan_reseller`

**Grain:** satu baris per baris pesanan reseller, yaitu satu produk dalam satu pesanan. Perkiraan 60.919 baris.
**Primary key:** `(nomor_pesanan, nomor_baris_pesanan)`.

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `nomor_pesanan` | VARCHAR(25) | Nomor pesanan penjualan (dimensi degeneratif) | SO43659 | Untuk menghitung jumlah pesanan dengan `COUNT(DISTINCT ...)` dan menelusuri ke sumber |
| `nomor_baris_pesanan` | INT | Nomor baris di sumber (`SalesOrderDetailID`) | 1 | Bersama `nomor_pesanan` membentuk primary key, sehingga ETL yang diulang tidak membuat data ganda |
| `nomor_po_reseller` | VARCHAR(25) NULL | Nomor purchase order dari toko | PO522145787 | Satu-satunya kolom yang boleh kosong |
| `tanggal_pesan_key` | INT | Tanggal pesanan dibuat | 20110531 | FK ke `dim_tanggal`, peran 1 |
| `tanggal_jatuh_tempo_key` | INT | Tanggal jatuh tempo pembayaran | 20110612 | FK ke `dim_tanggal`, peran 2 |
| `tanggal_kirim_key` | INT | Tanggal barang dikirim | 20110607 | FK ke `dim_tanggal`, peran 3 |
| `produk_key` | INT | Produk yang dijual | → Mountain-100 Black, 42 | FK ke `dim_produk` |
| `reseller_key` | INT | Toko pembeli | → Better Bike Shop | FK ke `dim_reseller` |
| `sales_person_key` | INT | Sales person pembuat pesanan, versi yang berlaku pada tanggal pesan | → Tsvi Reiter | FK ke `dim_sales_person` |
| `promosi_key` | INT | Promosi yang dipakai pada baris ini | → No Discount | FK ke `dim_promosi` |
| `kode_mata_uang` | CHAR(3) | Mata uang transaksi | USD | Bukan FK (tidak ada dimensinya). Kurs kosong di sumber berarti USD. `CHECK` panjang 3 huruf. Nilai: USD, CAD, GBP, EUR, AUD |
| `jumlah_unit` | INT | Jumlah unit terjual | 1 | Aditif. `CHECK > 0` |
| `nilai_penjualan` | DECIMAL(14,4) | Nilai setelah diskon, USD | 2024,9940 | Aditif. `OrderQty × UnitPrice × (1 − UnitPriceDiscount)`. `CHECK >= 0` |
| `nilai_diskon` | DECIMAL(14,4) | Potongan harga yang diberikan, USD | 0,0000 | Aditif. `OrderQty × UnitPrice × UnitPriceDiscount`. Bawaan 0 |
| `total_biaya_produk` | DECIMAL(14,4) | Biaya standar produk pada tanggal pesan × jumlah, USD | 1898,0944 | Aditif. `jumlah_unit × biaya_standar` dari versi `dim_produk` pada tanggal pesan. Biaya historis, bukan biaya terbaru |
| `harga_satuan` | DECIMAL(14,4) | Harga per unit sebelum diskon, USD | 2024,9940 | **Non-aditif.** Tampilkan sebagai rata-rata, jangan dijumlah |

Ukuran yang dihitung saat dipakai (tidak disimpan): margin kotor = `nilai_penjualan − total_biaya_produk`, persentase margin = margin ÷ `nilai_penjualan`, jumlah pesanan = `COUNT(DISTINCT nomor_pesanan)`.

Index: satu index untuk setiap foreign key (7 index, nama `ix_fpr_...`). Kolom ukuran tidak diberi index.

---

## `dim_produk` (struktur standar sponsor, SCD tipe 2 untuk biaya dan harga)

**Grain:** satu produk dalam satu periode biaya/harga (satu *versi* produk). **Perkiraan baris:** 606 versi untuk 504 produk + baris -1. **Natural key:** `produk_id`, unik bersama `berlaku_mulai`. 77 produk punya lebih dari satu versi.

Struktur kolom mengikuti standar dari sponsor (pertemuan 10) dan tidak ditambah atau dikurangi.

| Kolom | Tipe | SCD | Arti | Contoh | Catatan |
|-------|------|-----|------|--------|---------|
| `produk_key` | INT | - | Surrogate key, satu per versi | 1 | Primary key. Satu produk bisa punya beberapa `produk_key` |
| `produk_id` | INT | - | `ProductID` di sumber | 707 | Bersama `berlaku_mulai` unik (`uq_produk_versi`) |
| `nama_produk` | VARCHAR(50) | 1 | Nama lengkap | Sport-100 Helmet, Red | Kalau berubah, ditimpa di semua versi produk itu |
| `nomor_produk` | VARCHAR(25) | 0 | Kode produk | HL-U509-R | Tidak pernah diubah |
| `warna` | VARCHAR(15) | 1 | Warna | Red | Kosong di sumber → "Tidak ada" |
| `subkategori` | VARCHAR(50) | 1 | Subkategori | Helmets | Kosong → "Tanpa kategori" |
| `kategori` | VARCHAR(50) | 1 | Kategori | Accessories | Kosong → "Tanpa kategori" |
| `biaya_standar` | DECIMAL(12,4) | 2 | Biaya standar produk pada periode versi ini, USD | 13,0863 | Dasar `total_biaya_produk` di fakta |
| `harga_jual` | DECIMAL(12,4) | 2 | Harga katalog pada periode versi ini, USD | 34,9900 | Berbeda dengan `harga_satuan` di fakta (harga transaksi reseller) |
| `berlaku_mulai` | DATE | - | Tanggal pertama versi ini berlaku | 2013-05-30 | |
| `berlaku_sampai` | DATE | - | Tanggal terakhir versi ini berlaku | 9999-12-31 | 9999-12-31 = versi yang berlaku sekarang. `CHECK berlaku_mulai <= berlaku_sampai` |
| `is_current` | BOOLEAN | - | 1 jika versi ini berlaku sekarang | 1 | Sama dengan `berlaku_sampai = 9999-12-31` |

Hierarki: Kategori → Subkategori → Produk. Hierarki kedua: Warna → Produk.

Cara fakta memilih versi: `produk_id` sama dan tanggal pesan di antara `berlaku_mulai` dan `berlaku_sampai`. Contoh Sport-100 Helmet, Red: tiga versi (biaya 12,0278 → 13,8782 → 13,0863), sehingga pesanan 2012-05-29 dan 2012-05-30 menunjuk ke `produk_key` yang berbeda. Karena satu produk punya beberapa key, hitung per produk dengan `GROUP BY produk_id`, bukan `produk_key`.

## `dim_reseller` (SCD tipe 1)

**Grain:** satu toko. **Perkiraan baris:** 701 + baris -1. **Natural key unik:** `reseller_id`. Dimensi khusus tim reseller. Membawa wilayah penjualan toko.

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `reseller_key` | INT | Surrogate key | 1 | Primary key |
| `reseller_id` | INT | `BusinessEntityID` toko | 1046 | Unik |
| `nama_reseller` | VARCHAR(50) | Nama toko | Better Bike Shop | |
| `tipe_bisnis` | VARCHAR(30) | Jenis usaha toko | Value Added Reseller | Dari kode XML BM / BS / OS |
| `spesialisasi` | VARCHAR(20) | Spesialisasi sepeda | Mountain | Mountain, Road, atau Touring |
| `tahun_buka` | INT | Tahun toko dibuka | 1975 | -1 = tidak diketahui |
| `jumlah_karyawan` | INT | Jumlah karyawan | 19 | -1 = tidak diketahui |
| `kota` | VARCHAR(30) | Kota alamat Main Office | Austell | |
| `provinsi` | VARCHAR(50) | Provinsi atau negara bagian | Georgia | |
| `negara` | VARCHAR(50) | Negara lokasi kantor toko | United States | |
| `nama_wilayah` | VARCHAR(50) | Wilayah penjualan toko | Southeast | Berbeda dengan lokasi kantor. Satu toko, satu wilayah. 10 wilayah |
| `negara_wilayah` | VARCHAR(50) | Negara dari wilayah penjualan | United States | |
| `grup_wilayah` | VARCHAR(50) | Grup besar wilayah | North America | North America, Europe, Pacific |

Hierarki lokasi: Negara → Provinsi → Kota → Reseller. Hierarki wilayah: Grup wilayah → Wilayah → Reseller.

## `dim_sales_person` (SCD tipe 2)

**Grain:** satu sales person pada satu periode wilayah tugas. **Perkiraan baris:** 20 versi + baris -1. **Unik:** `(sales_person_id, berlaku_mulai)`.

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `sales_person_key` | INT | Surrogate key, **satu per versi** | 12 | Primary key. Orang yang sama bisa punya beberapa key |
| `sales_person_id` | INT | `BusinessEntityID` | 282 | **Tidak unik sendirian** karena ada beberapa versi |
| `nama_sales_person` | VARCHAR(150) | Nama depan + belakang | José Saraiva | |
| `jabatan` | VARCHAR(50) | Jabatan | Sales Representative | |
| `wilayah_tugas` | VARCHAR(50) | Wilayah tanggung jawab pada periode ini | Canada | Manajer: "Tidak ada wilayah" |
| `persen_komisi` | DECIMAL(6,4) | Persentase komisi | 0,0100 | |
| `berlaku_mulai` | DATE | Awal periode | 2011-05-31 | Manajer: 1900-01-01 |
| `berlaku_sampai` | DATE | Akhir periode | 2012-05-29 | Versi terakhir: 9999-12-31 |
| `is_current` | BOOLEAN | Versi yang berlaku sekarang | 0 | Disimpan sebagai TINYINT 0/1 |

Constraint tambahan: `CHECK (berlaku_mulai <= berlaku_sampai)`. Pencarian di ETL: `sales_person_id` sama dan tanggal pesan di antara `berlaku_mulai` dan `berlaku_sampai`.

## `dim_promosi` (SCD tipe 1)

**Grain:** satu program promosi. **Perkiraan baris:** 16 + baris -1. **Natural key unik:** `promosi_id`.

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `promosi_key` | INT | Surrogate key | 1 | |
| `promosi_id` | INT | `SpecialOfferID` | 13 | Unik |
| `nama_promosi` | VARCHAR(255) | Deskripsi | Touring-3000 Promotion | |
| `jenis_promosi` | VARCHAR(50) | Jenis | New Product | |
| `kategori_promosi` | VARCHAR(50) | Sasaran promosi | Reseller | |
| `persen_diskon` | DECIMAL(6,4) | Diskon resmi promosi | 0,1500 | Aturan promosi, berbeda dengan `nilai_diskon` di fakta |
| `tanggal_mulai` | DATE | Awal masa berlaku | 2013-05-30 | |
| `tanggal_selesai` | DATE | Akhir masa berlaku | 2013-08-29 | |
| `qty_min` | INT | Jumlah beli minimal | 0 | |
| `qty_maks` | INT | Jumlah beli maksimal | -1 | -1 = tanpa batas atas (NULL di sumber) |

"No Discount" (id 1) adalah satu baris promosi biasa dengan diskon 0.

## `dim_tanggal` (standar sponsor, tidak diubah)

Dipasang dari skrip standar, bukan dibuat tim. Isi bagian ini **setelah skripnya diunduh dan dijalankan**, dengan bahasa sendiri.

Fakta yang sudah diketahui dari halaman tugas pekan 11:

- 2.192 baris: setiap hari dari 2010-01-01 sampai 2015-12-31, ditambah baris -1.
- `tanggal_key` berformat YYYYMMDD (contoh 20130315, yang harus hari Jumat).
- Baris -1 memakai tanggal 1900-01-01.
- Hari pertama minggu adalah Senin. `minggu_dalam_tahun` mengikuti ISO 8601.
- Dipakai tiga kali oleh fakta (tanggal pesan, jatuh tempo, kirim).

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `tanggal_key` | INT | Tanggal dalam bentuk angka YYYYMMDD | 20110531 | Primary key. Lihat pertanyaan di bawah |
| (isi dari skrip yang diunduh) | | | | |

Pertanyaan yang harus dijawab di kolom catatan (dari halaman tugas):

1. Kenapa `tanggal_key` berformat YYYYMMDD dan bukan angka urut? *Jawaban tim: ______*
2. Kenapa baris -1 memakai tanggal 1900-01-01? *Jawaban tim: ______*
3. Kenapa hari pertama minggu adalah Senin? *Jawaban tim: ______*

Jika tim butuh atribut tambahan (misalnya hari libur), buat tabel terpisah yang terhubung lewat `tanggal_key`, jangan mengubah tabel standar.
