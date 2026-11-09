# Kamus Data Data Warehouse Penjualan Reseller

Kelompok : X
Database : `dw_kelompok_x` (MySQL/MariaDB XAMPP, mesin InnoDB)
Skrip    : `sql/ddl.sql` (star schema v2, 8 dimensi), `sql/dim_tanggal_mysql.sql` (skrip standar sponsor, versi 1.0, dipasang sebelum `ddl.sql`)
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
| `wilayah_key` | INT | Wilayah penjualan pesanan | → Southeast | FK ke `dim_wilayah`. Sama dengan wilayah toko pembeli |
| `mata_uang_key` | INT | Mata uang transaksi | → US Dollar | FK ke `dim_mata_uang`. Kurs kosong di sumber berarti USD. Yang terpakai: USD, CAD, GBP, EUR, AUD |
| `metode_key` | INT | Metode kirim pesanan | → CARGO TRANSPORT 5 | FK ke `dim_metode_kirim`. Semua pesanan reseller memakai satu metode |
| `jumlah_unit` | INT | Jumlah unit terjual | 1 | Aditif. `CHECK > 0` |
| `nilai_penjualan` | DECIMAL(14,4) | Nilai setelah diskon, USD | 2024,9940 | Aditif. `OrderQty × UnitPrice × (1 − UnitPriceDiscount)`. `CHECK >= 0` |
| `nilai_diskon` | DECIMAL(14,4) | Potongan harga yang diberikan, USD | 0,0000 | Aditif. `OrderQty × UnitPrice × UnitPriceDiscount`. Bawaan 0 |
| `total_biaya_produk` | DECIMAL(14,4) | Biaya standar produk pada tanggal pesan × jumlah, USD | 1898,0944 | Aditif. `jumlah_unit × biaya_standar` dari versi `dim_produk` pada tanggal pesan. Biaya historis, bukan biaya terbaru |
| `harga_satuan` | DECIMAL(14,4) | Harga per unit sebelum diskon, USD | 2024,9940 | **Non-aditif.** Tampilkan sebagai rata-rata, jangan dijumlah |

Ukuran yang dihitung saat dipakai (tidak disimpan): margin kotor = `nilai_penjualan − total_biaya_produk`, persentase margin = margin ÷ `nilai_penjualan`, jumlah pesanan = `COUNT(DISTINCT nomor_pesanan)`.

Index: satu index untuk setiap foreign key (10 index, nama `ix_fpr_...`). Kolom ukuran tidak diberi index.

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

**Grain:** satu toko. **Perkiraan baris:** 701 + baris -1. **Natural key unik:** `reseller_id`. Dimensi khusus tim reseller. Hanya membawa lokasi kantor toko; wilayah penjualan ada di `dim_wilayah`.

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

Hierarki lokasi: Negara → Provinsi → Kota → Reseller. Wilayah penjualan toko diambil dari `dim_wilayah` lewat fakta (wilayah pesanan sama dengan wilayah toko pada 3.806 dari 3.806 pesanan).

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

## `dim_wilayah` (SCD tipe 1)

**Grain:** satu wilayah penjualan. **Baris:** 10 + baris -1. **Natural key unik:** `wilayah_id`. Dimensi conformed (dipakai Penjualan Online, Penjualan Reseller, Kinerja Sales, Alasan Pembelian Pelanggan).

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `wilayah_key` | INT | Surrogate key | 1 | Primary key |
| `wilayah_id` | INT | `TerritoryID` | 5 | Unik |
| `nama_wilayah` | VARCHAR(50) | Nama wilayah penjualan | Southeast | Northwest, Northeast, Central, Southwest, Southeast, Canada, France, Germany, Australia, United Kingdom |
| `kode_negara` | VARCHAR(3) | Kode negara | US | US, CA, FR, DE, AU, GB |
| `nama_negara` | VARCHAR(50) | Nama negara | United States | |
| `grup_wilayah` | VARCHAR(50) | Grup besar wilayah | North America | North America, Europe, Pacific |

Hierarki: Grup wilayah → Negara → Wilayah. Beda dengan `wilayah_tugas` di `dim_sales_person`, yaitu wilayah tempat seorang sales person bertugas pada periode tertentu.

## `dim_mata_uang` (SCD tipe 1)

**Grain:** satu mata uang. **Baris:** 105 + baris -1. **Natural key unik:** `kode_mata_uang`. Dimensi conformed (Penjualan Online dan Penjualan Reseller).

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `mata_uang_key` | INT | Surrogate key | 1 | Primary key |
| `kode_mata_uang` | CHAR(3) | Kode ISO | USD | Unik. Baris -1 memakai `---` |
| `nama_mata_uang` | VARCHAR(100) | Nama mata uang | US Dollar | |

Pesanan reseller hanya memakai lima kode: USD (2.629 pesanan), CAD (692), GBP (188), EUR (172), AUD (125). Seluruh nilai uang di fakta tetap dalam USD.

## `dim_metode_kirim` (SCD tipe 1)

**Grain:** satu metode kirim. **Baris:** 5 + baris -1. **Natural key unik:** `metode_id`. Dimensi conformed (Penjualan Online, Penjualan Reseller, Pembelian).

| Kolom | Tipe | Arti | Contoh | Catatan |
|-------|------|------|--------|---------|
| `metode_key` | INT | Surrogate key | 1 | Primary key |
| `metode_id` | INT | `ShipMethodID` | 5 | Unik |
| `nama_metode` | VARCHAR(50) | Nama metode | CARGO TRANSPORT 5 | |
| `tarif_dasar` | DECIMAL(12,4) | Tarif dasar pengiriman | 8,9900 | `ShipBase` |
| `tarif_per_kg` | DECIMAL(12,4) | Tarif per kilogram | 1,4900 | `ShipRate` |

Semua 3.806 pesanan reseller memakai CARGO TRANSPORT 5. Empat metode lain (XRQ - TRUCK GROUND, ZY - EXPRESS, OVERSEAS - DELUXE, OVERNIGHT J-FAST) ada di dimensi tetapi tidak dipakai proses ini.

## `dim_tanggal` (standar sponsor v1.0, SCD tipe 0, tidak diubah)

**Grain:** satu hari. **Baris:** 2.192 (2.191 hari dari 2010-01-01 sampai 2015-12-31, ditambah baris -1). **Natural key unik:** `tanggal` (UNIQUE).

Dipasang dari `sql/dim_tanggal_mysql.sql` (salinan persis skrip dosen, versi 1.0, butuh MySQL 8.0+ karena memakai recursive CTE). Skrip ini **tidak boleh diubah**. Tabel dipakai tiga kali oleh fakta (role-playing): tanggal pesan, tanggal jatuh tempo, dan tanggal kirim.

| Kolom | Tipe | Arti | Contoh (20130315) | Catatan |
|-------|------|------|-------------------|---------|
| `tanggal_key` | INT | Tanggal dalam bentuk angka YYYYMMDD | 20130315 | Primary key. -1 = tidak diketahui |
| `tanggal` | DATE | Tanggal sebenarnya | 2013-03-15 | Unik. Baris -1 berisi 1900-01-01 |
| `tahun` | INT | Tahun kalender | 2013 | Baris -1 berisi 0 |
| `semester` | INT | 1 = Januari sampai Juni, 2 = Juli sampai Desember | 1 | |
| `kuartal` | INT | 1 sampai 4 | 1 | |
| `bulan` | INT | 1 sampai 12 | 3 | |
| `nama_bulan` | VARCHAR(15) | Januari sampai Desember | Maret | Baris -1: Tidak diketahui |
| `minggu_dalam_tahun` | INT | Minggu ISO 8601, 1 sampai 53 | 11 | 1 Januari bisa masuk minggu 52 atau 53 tahun sebelumnya (2010-01-01 minggu 53, 2011-01-01 minggu 52, 2012-01-01 minggu 52) |
| `tanggal_dalam_bulan` | INT | 1 sampai 31 | 15 | |
| `hari_dalam_minggu` | INT | Senin = 1 sampai Minggu = 7 | 5 | |
| `nama_hari` | VARCHAR(15) | Senin sampai Minggu | Jumat | Baris -1: Tidak diketahui |
| `is_akhir_pekan` | BOOLEAN | 1 untuk Sabtu dan Minggu | 0 | |

Hierarki untuk cube: **Tahun → Kuartal → Bulan → Tanggal** (kolom `tahun`, `kuartal`, `bulan`, `tanggal`). Kolom `semester`, `minggu_dalam_tahun`, dan `nama_hari` tersedia bila dashboard membutuhkannya, tetapi kelima pertanyaan bisnis hanya memakai tahun dan kuartal.

Baris -1 berisi nol dan teks "Tidak diketahui". Pesanan reseller di sumber selalu punya ketiga tanggal, sehingga tidak ada fakta yang memakai baris -1 untuk tanggal.

Tiga pertanyaan dari halaman tugas, dijawab dengan bahasa tim (**tim membaca ulang dan mengubah jawaban ini dengan kata-kata sendiri sebelum dikumpulkan**):

1. **Kenapa `tanggal_key` berformat YYYYMMDD dan bukan angka urut?** Angka YYYYMMDD bisa dibaca manusia tanpa membuka dimensi (20130315 pasti 15 Maret 2013), urutannya sama dengan urutan kalender, dan ETL bisa menghitungnya langsung dari tanggal sumber (`DATE_FORMAT(OrderDate, '%Y%m%d')`) tanpa mencari ke tabel. Angka urut tidak bermakna sehingga salah isi sulit ketahuan.
2. **Kenapa baris -1 memakai tanggal 1900-01-01?** Kolom `tanggal` wajib terisi (NOT NULL) dan unik, jadi baris -1 butuh tanggal. 1900-01-01 berada jauh di luar rentang data (2010 sampai 2015), sehingga tidak bentrok dengan hari asli dan langsung terlihat sebagai tanggal pengganti.
3. **Kenapa hari pertama minggu adalah Senin?** Skrip mengikuti standar ISO 8601: minggu mulai Senin, dan nomor minggu dihitung dengan `WEEK(d, 3)`. Dengan begitu `hari_dalam_minggu` Senin = 1 sampai Minggu = 7, dan akhir pekan jatuh di hari ke-6 dan ke-7. Satu aturan yang sama dipakai semua kelompok, sehingga angka antartim bisa digabung.

Jika tim butuh atribut tambahan (misalnya hari libur), buat tabel terpisah yang terhubung lewat `tanggal_key`, jangan mengubah tabel standar.
