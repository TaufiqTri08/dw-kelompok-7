# Narasi Star Schema v2: Penjualan Reseller

Kelompok : X
Diagram  : `docs/star-schema-v2.png` (versi yang bisa diedit: `docs/star-schema-v2.dbml`)
Tabel    : `sql/ddl.sql`. Kamus data: `docs/kamus-data.md`

Semua angka di dokumen ini diambil dari database sumber `adventureworks2` (data 31 Mei 2011 sampai 1 Mei 2014).

---

## 1. Gambaran besar dalam satu paragraf

Star schema ini menjawab satu hal: **bagaimana kinerja penjualan Adventure Works ke toko reseller**. Di tengah ada **satu tabel fakta** yang berisi angka penjualan, satu baris untuk setiap produk dalam setiap pesanan (60.919 baris). Di sekelilingnya ada **delapan dimensi** yang menjelaskan angka itu: **kapan** (tanggal), **apa** (produk), **ke siapa** (reseller), **oleh siapa** (sales person), **dengan promosi apa** (promosi), **di wilayah mana** (wilayah), **dalam mata uang apa** (mata uang), dan **dikirim dengan apa** (metode kirim).

| Tabel | Jenis | Satu baris mewakili | Jumlah baris | Pertanyaan yang dijawab |
|-------|-------|---------------------|--------------|-------------------------|
| `fact_penjualan_reseller` | Fakta | Satu produk dalam satu pesanan | 60.919 | Berapa banyak dan berapa nilainya? |
| `dim_tanggal` | Dimensi | Satu hari | 2.192 + baris -1 | Kapan? |
| `dim_produk` | Dimensi | Satu produk pada satu periode biaya dan harga (satu versi) | 606 (untuk 504 produk) + baris -1 | Apa yang dijual? |
| `dim_reseller` | Dimensi | Satu toko | 701 + baris -1 | Dijual ke siapa? |
| `dim_sales_person` | Dimensi | Satu sales person pada satu periode wilayah tugas | 20 + baris -1 | Dijual oleh siapa? |
| `dim_promosi` | Dimensi | Satu program promosi | 16 + baris -1 | Dengan promosi apa? |
| `dim_wilayah` | Dimensi | Satu wilayah penjualan | 10 + baris -1 | Di wilayah mana? |
| `dim_mata_uang` | Dimensi | Satu mata uang | 105 + baris -1 | Dalam mata uang apa? |
| `dim_metode_kirim` | Dimensi | Satu metode kirim | 5 + baris -1 | Dikirim dengan apa? |

Setiap dimensi punya satu baris tambahan "Tidak diketahui" dengan key -1 (bagian 6).

---

## 2. Kenapa delapan dimensi?

Baris Penjualan Reseller di **bus matrix kelas** (Pertemuan 9) bertanda ● pada delapan dimensi: Tanggal, Produk, Wilayah, Promosi, Mata Uang, Metode Kirim, Sales Person, dan Reseller. Star schema ini mengikuti matriks itu, dan tiga dimensi yang dipakai bersama proses lain (Wilayah dipakai 4 proses, Metode Kirim 3, Mata Uang 2) dibuat sebagai tabel sendiri supaya penggabungan data antartim memakai dimensi yang sama.

Kami juga memeriksa isi datanya. Hasilnya jujur: tiga dimensi berisi sedikit nilai.

| Dimensi | Isi di data reseller | Kenapa tetap tabel sendiri |
|---------|----------------------|----------------------------|
| `dim_wilayah` | 10 wilayah, semuanya terpakai. Wilayah pesanan **sama** dengan wilayah toko pada 3.806 dari 3.806 pesanan | Conformed dengan 3 proses lain. Wilayah tetap perlu dianalisis (P3), dan hierarki Grup → Negara → Wilayah lebih bersih di tabel sendiri daripada tiga kolom di `dim_reseller` |
| `dim_mata_uang` | 105 kode di tabel, 5 terpakai (USD 2.629 pesanan, CAD 692, GBP 188, EUR 172, AUD 125) | Conformed dengan Penjualan Online. Memisahkan "mata uang transaksi" dari angka uang yang selalu USD |
| `dim_metode_kirim` | 5 metode di tabel, **hanya 1 terpakai** (CARGO TRANSPORT 5, 3.806 pesanan) | Conformed dengan Penjualan Online dan Pembelian. Saat ini tidak membedakan apa pun, tetapi strukturnya siap bila metode lain dipakai |

Kandidat yang kami periksa dan **tidak dibuat**:

| Kandidat | Keputusan | Alasan |
|----------|-----------|--------|
| Pelanggan | Tidak dibuat | Pembeli di proses ini adalah toko, bukan perorangan. Dipakai `dim_reseller` |
| Metode pembayaran (tipe kartu kredit) | Ditunda | Data ada (3.799 dari 3.806 pesanan punya kartu, 4 tipe), tetapi tidak ada di bus matrix kelas dan tidak dipakai kelima pertanyaan bisnis. Bisa ditambahkan lewat permintaan perubahan |
| Vendor, Alasan Scrap | Tidak dibuat | Milik proses pembelian dan produksi |

Kenapa wilayah tidak digabung ke `dim_sales_person` saja? Karena dua hal itu berbeda. Pada 1.429 pesanan (38%), wilayah penjualan berbeda dengan wilayah tugas sales person. Wilayah penjualan mengikuti **toko**, sedangkan wilayah tugas mengikuti **sales person** dan bisa berubah. Karena itu keduanya disimpan terpisah: `dim_wilayah` untuk wilayah penjualan, dan kolom `wilayah_tugas` (SCD tipe 2) di `dim_sales_person`.

---

## 3. Tabel fakta: `fact_penjualan_reseller`

### Grain

> Satu baris mewakili satu baris pesanan reseller, yaitu satu produk dalam satu pesanan penjualan yang dibuat sales person untuk sebuah toko reseller.

Kalau sebuah toko memesan 12 jenis produk dalam satu pesanan, pesanan itu menjadi 12 baris. Pesanan SO43659 adalah contohnya: 12 baris, 26 unit. Grain ini dipilih karena paling rinci: dari baris pesanan, total per bulan, per toko, atau per sales person selalu bisa dihitung, tetapi tidak sebaliknya.

### Isi tabel fakta

**a. Kunci ke dimensi (10 kolom, 8 dimensi):**

| Kolom | Menunjuk ke | Dari sumber |
|-------|-------------|-------------|
| `tanggal_pesan_key` | `dim_tanggal` | `OrderDate` |
| `tanggal_jatuh_tempo_key` | `dim_tanggal` | `DueDate` |
| `tanggal_kirim_key` | `dim_tanggal` | `ShipDate` |
| `produk_key` | `dim_produk` | `ProductID` di baris pesanan |
| `reseller_key` | `dim_reseller` | `CustomerID` → `StoreID` |
| `sales_person_key` | `dim_sales_person` | `SalesPersonID` + tanggal pesan |
| `promosi_key` | `dim_promosi` | `SpecialOfferID` di baris pesanan |
| `wilayah_key` | `dim_wilayah` | `TerritoryID` di header pesanan |
| `mata_uang_key` | `dim_mata_uang` | `CurrencyRateID` → `ToCurrencyCode` (kosong = USD) |
| `metode_key` | `dim_metode_kirim` | `ShipMethodID` di header pesanan |

**b. Dimensi degeneratif** (nomor yang tidak punya atribut lain, disimpan langsung di fakta):
`nomor_pesanan` (SO43659), `nomor_baris_pesanan` (1), dan `nomor_po_reseller` (PO522145787). Dua yang pertama membentuk primary key, sehingga ETL yang diulang tidak membuat data ganda.

**c. Catatan `mata_uang_key`:** menunjuk mata uang transaksi (USD, CAD, GBP, EUR, AUD). Kurs kosong di sumber berarti USD (2.629 pesanan). Semua nilai uang di fakta tetap dalam USD.

**d. Ukuran (measure):**

| Kolom | Rumus dari sumber | Jenis | Cara dijumlahkan |
|-------|-------------------|-------|------------------|
| `jumlah_unit` | `OrderQty` | Aditif | SUM |
| `nilai_penjualan` | `OrderQty × UnitPrice × (1 − UnitPriceDiscount)` | Aditif | SUM |
| `nilai_diskon` | `OrderQty × UnitPrice × UnitPriceDiscount` | Aditif | SUM |
| `total_biaya_produk` | `OrderQty × biaya standar pada tanggal pesan` | Aditif | SUM |
| `harga_satuan` | `UnitPrice` | **Non-aditif** | Rata-rata, jangan dijumlah |

Yang **tidak disimpan** tetapi dihitung saat ditampilkan: margin kotor (`nilai_penjualan − total_biaya_produk`), persentase margin, dan jumlah pesanan (`COUNT(DISTINCT nomor_pesanan)`). Persentase tidak disimpan karena non-aditif: kalau dijumlahkan, hasilnya salah.

### Contoh satu baris

Baris pertama pesanan SO43659:

| Kolom | Isi | Artinya |
|-------|-----|---------|
| `tanggal_pesan_key` | 20110531 | Dipesan 31 Mei 2011 |
| `tanggal_jatuh_tempo_key` | 20110612 | Jatuh tempo 12 Juni 2011 |
| `tanggal_kirim_key` | 20110607 | Dikirim 7 Juni 2011 |
| `produk_key` | → | Mountain-100 Black, 42 |
| `reseller_key` | → | Better Bike Shop |
| `sales_person_key` | → | Tsvi Reiter |
| `promosi_key` | → | No Discount |
| `wilayah_key` | → | Southeast |
| `mata_uang_key` | → | US Dollar |
| `metode_key` | → | CARGO TRANSPORT 5 |
| `nomor_pesanan` | SO43659 | |
| `jumlah_unit` | 1 | |
| `nilai_penjualan` | 2.024,9940 | |
| `total_biaya_produk` | 1.898,0944 | |
| `harga_satuan` | 2.024,9940 | |

Dibaca sebagai kalimat: *"Pada 31 Mei 2011, sales person Tsvi Reiter menjual 1 sepeda Mountain-100 Black ukuran 42 ke toko Better Bike Shop di wilayah Southeast, tanpa diskon, dikirim dengan CARGO TRANSPORT 5, senilai USD 2.024,99, dengan biaya produk USD 1.898,09."*

---

## 4. Dimensi satu per satu

### 4.1 `dim_tanggal`: kapan?

Satu baris = satu hari. Bukan dari tabel sumber dan bukan dibuat tim: dipasang dari **skrip standar sponsor** (v1.0), berisi 2.192 hari dari 1 Januari 2010 sampai 31 Desember 2015. `tanggal_key` berformat YYYYMMDD (contoh 20110531). Tabelnya punya 12 kolom: `tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari`, `is_akhir_pekan` (penjelasan di `docs/kamus-data.md`). Hierarki: Tahun → Kuartal → Bulan → Tanggal.

- **Dipakai tiga kali oleh fakta** (role-playing): tanggal pesan, tanggal jatuh tempo, dan tanggal kirim. Tabelnya satu, perannya tiga. Di diagram ada tiga garis ke tabel yang sama.
- Pesanan reseller hanya terjadi pada **40 hari berbeda**, karena toko memesan serentak. Analisis per bulan atau kuartal lebih bermakna daripada per hari.
- Jatuh tempo dan pengiriman hampir selalu 12 dan 7 hari setelah tanggal pesan (3.797 dari 3.806 pesanan).
- Zona waktu: `OrderDate` di dump tergeser −05:30, dibaca dengan `SET time_zone = '+05:30'`.

### 4.2 `dim_produk`: apa yang dijual?

Satu baris = satu produk pada satu periode biaya dan harga (satu *versi*): **606 baris untuk 504 produk**. Strukturnya mengikuti **standar dari sponsor** (12 kolom). Sumber: lima tabel yang digabung jadi satu (denormalisasi): produk, subkategori, kategori, riwayat biaya, dan riwayat harga.

| Kolom penting | Contoh (Sport-100 Helmet, Red, versi terbaru) |
|---------------|-----------------------------------------------|
| `nama_produk` | Sport-100 Helmet, Red |
| `kategori` → `subkategori` | Accessories → Helmets |
| `warna` | Red |
| `biaya_standar` (SCD 2) | 13,0863 |
| `harga_jual` (SCD 2) | 34,99 |
| `berlaku_mulai`, `berlaku_sampai`, `is_current` | 2013-05-30, 9999-12-31, ya |

- **Hierarki:** Kategori (4) → Subkategori (37) → Produk (504). Hierarki kedua: Warna → Produk.
- **Satu produk bisa punya beberapa baris.** Sport-100 Helmet, Red punya tiga versi karena biaya dan harganya berganti (biaya 12,0278 → 13,8782 → 13,0863). Fakta memilih versi yang berlaku pada tanggal pesan. Karena itu, menghitung per produk memakai `produk_id`, bukan `produk_key`.
- **Produk lain hanya punya satu versi.** Mountain-100 Black, 42 (produk 776) punya satu periode di sumber, sehingga hanya satu baris, berlaku sampai 9999-12-31.
- **`harga_jual` berbeda dengan `harga_satuan` di fakta.** Harga katalog Mountain-100 Black, 42 adalah 3.374,99, harga yang dibayar reseller 2.024,99.
- Warna kosong (28 dari 250 produk yang terjual) diisi "Tidak ada". Produk tanpa subkategori (209 produk, tidak ada yang terjual) diisi "Tanpa kategori".
- Kolom `ukuran`, `garis_produk`, `model`, `harga_list`, dan `status_jual` dari v1 tidak ada lagi di v2, karena tidak dipakai oleh kelima pertanyaan bisnis dan strukturnya harus sama dengan standar.
- **Apa itu `garis_produk` dan `model`?** Dua pengelompokan produk yang sudah ada di sumber, di luar kategori dan subkategori.
  - `garis_produk` (`production_product.ProductLine`) adalah kode satu huruf untuk lini produk: R = Road, M = Mountain, T = Touring, S = Standard. Dari 504 produk, 100 berkode R, 91 M, 52 T, 35 S, dan 226 kosong (suku cadang dan komponen). Dari 250 produk yang terjual ke reseller, 77 berkode R, 81 M, 45 T, 32 S, dan 15 kosong.
  - `model` (`production_productmodel.Name`) adalah nama desain induk yang dipakai beberapa varian produk. Misalnya model *Road-150* punya 5 varian (Road-150 Red, 44 dan seterusnya), *Mountain-200* punya 6 varian (beda warna dan ukuran). Ada 119 model, dan semua 250 produk yang terjual punya model.
  - Bedanya dengan kategori: kategori menjawab "jenis barang apa" (Bikes, Components, Clothing, Accessories), garis produk menjawab "untuk gaya berkendara apa" (jalan raya, gunung, touring), dan model menjawab "desain yang mana" (satu model, banyak ukuran dan warna).
  - Tidak ada di v2 karena standar `dim_produk` dari sponsor berisi 12 kolom tertentu dan tidak memuat keduanya, sedangkan kelima pertanyaan bisnis cukup dijawab dengan kategori, subkategori, dan produk. Kalau sponsor ingin analisis per lini atau per model, kami ajukan permintaan perubahan (`docs/perubahan/CR-xx.md`) berupa tabel tambahan (mis. `dim_produk_atribut`) yang terhubung lewat `produk_id`, supaya tabel standar tidak berubah.

### 4.3 `dim_reseller`: dijual ke siapa?

Satu baris = satu toko (701, dan 635 di antaranya pernah membeli). Ini satu-satunya dimensi khusus tim reseller (tujuh dimensi lain dipakai bersama proses lain). Pembeli di proses ini adalah **toko, bukan orang**, sehingga tidak ada dimensi pelanggan.

| Kelompok kolom | Kolom | Contoh (Better Bike Shop) |
|----------------|-------|----------------------------|
| Identitas | `nama_reseller` | Better Bike Shop |
| Profil usaha (dari XML) | `tipe_bisnis`, `spesialisasi`, `tahun_buka`, `jumlah_karyawan` | Value Added Reseller, Mountain, 1975, 19 |
| **Lokasi kantor toko** | `kota`, `provinsi`, `negara` | Austell, Georgia, United States |

- **Hierarki lokasi:** Negara → Provinsi → Kota → Reseller.
- **Lokasi kantor dan wilayah penjualan adalah dua hal berbeda.** Austell, Georgia adalah alamat toko. Wilayah penjualan yang menaungi toko itu (Southeast) disimpan di `dim_wilayah` dan dihubungkan lewat fakta.
- Tipe bisnis: BM = Value Added Reseller (238), BS = Specialty Bike Shop (231), OS = Warehouse (232).
- 11 toko punya dua alamat. Yang dipakai adalah alamat Main Office, supaya satu toko tetap satu baris.

### 4.4 `dim_sales_person`: dijual oleh siapa?

Satu baris = satu sales person **pada satu periode wilayah tugas**. Ada 17 sales person tetapi 20 baris, karena tiga orang pindah wilayah.

| Kolom penting | Contoh |
|---------------|--------|
| `nama_sales_person` | José Saraiva |
| `jabatan` | Sales Representative |
| `wilayah_tugas` | Canada, lalu United Kingdom |
| `persen_komisi` | 1% |
| `berlaku_mulai`, `berlaku_sampai`, `is_current` | 2011-05-31, 2012-05-29, tidak |

- **Sales person diambil dari pesanan, bukan dari toko.** Pada 1.563 pesanan (41%), sales person di pesanan berbeda dengan sales person toko saat ini.
- **Manajer** (Stephen Jiang, Syed Abbas, Amy Alberts) tidak punya wilayah tugas, tetapi tetap punya 103 pesanan. `wilayah_tugas` mereka diisi "Tidak ada wilayah".
- Dimensi kedua yang memakai **SCD tipe 2**, selain `dim_produk` (bagian 5).

### 4.5 `dim_promosi`: dengan promosi apa?

Satu baris = satu program promosi (16, dan 12 dipakai reseller).

| Kolom penting | Contoh |
|---------------|--------|
| `nama_promosi` | Touring-3000 Promotion |
| `jenis_promosi` | New Product |
| `persen_diskon` | 15% |
| `tanggal_mulai`, `tanggal_selesai` | 30 Mei 2013 – 29 Agustus 2013 |

- **"No Discount" juga satu baris promosi**, dipakai 57.637 dari 60.919 baris. Karena itu `promosi_key` di fakta tidak pernah kosong.
- Promosi dicatat **per baris pesanan**, bukan per pesanan: 902 pesanan memakai promosi berbeda-beda di barisnya. Itulah alasan grain dibuat per baris.
- `persen_diskon` di dimensi adalah aturan promosi. `nilai_diskon` di fakta adalah potongan yang benar-benar terjadi.

### 4.6 `dim_wilayah`: di wilayah mana?

Satu baris = satu wilayah penjualan (10 wilayah). Wilayah pesanan sama dengan wilayah toko pembeli pada 3.806 dari 3.806 pesanan.

| Kolom | Contoh |
|-------|--------|
| `nama_wilayah` | Southeast |
| `kode_negara`, `nama_negara` | US, United States |
| `grup_wilayah` | North America |

- **Hierarki:** Grup wilayah (3: North America, Europe, Pacific) → Negara (6) → Wilayah (10). Amerika Serikat dibagi lima wilayah (Northwest, Northeast, Central, Southwest, Southeast), sedangkan Canada, France, Germany, United Kingdom, dan Australia masing-masing satu wilayah.
- **Pesanan per wilayah:** Southwest 751, Canada 692, Northwest 536, Southeast 469, Central 376, Northeast 342, France 188, United Kingdom 188, Germany 139, Australia 125.
- **Nilai penjualan per grup:** North America USD 67.985.726,79 (3.166 pesanan), Europe USD 10.907.642,01 (515), Pacific USD 1.594.335,37 (125).
- Jangan tertukar dengan `wilayah_tugas` di `dim_sales_person` (wilayah tempat sales person bertugas, bisa berubah).

### 4.7 `dim_mata_uang`: dalam mata uang apa?

Satu baris = satu mata uang (105 di sumber, ditambah baris -1). Pesanan reseller hanya memakai lima: USD (2.629 pesanan), CAD (692), GBP (188), EUR (172), AUD (125). Dimensi ini mencatat mata uang transaksi; seluruh nilai uang di fakta tetap dalam USD, sehingga memilih mata uang tidak mengubah angka yang dijumlahkan.

### 4.8 `dim_metode_kirim`: dikirim dengan apa?

Satu baris = satu metode kirim (5 di sumber, ditambah baris -1). Seluruh 3.806 pesanan reseller memakai CARGO TRANSPORT 5 (tarif dasar 8,99 dan 1,49 per kg). Empat metode lain dimuat supaya dimensi sama dengan tim lain, tetapi tidak dipakai proses ini.

---

## 5. Bagian yang berubah: strategi SCD

SCD (*slowly changing dimension*) menjawab: kalau atribut dimensi berubah, apa yang terjadi pada data lama?

| Dimensi | Tipe | Atribut yang bisa berubah | Alasan |
|---------|------|---------------------------|--------|
| `dim_sales_person` | **Tipe 2** (tambah baris baru) | `wilayah_tugas` | Data membuktikan tiga orang pindah wilayah. Analisis kinerja harus memakai wilayah saat pesanan dibuat |
| `dim_produk` | **Tipe 2** untuk `biaya_standar` dan `harga_jual`; tipe 1 untuk nama, warna, subkategori, kategori; tipe 0 untuk `nomor_produk` | biaya standar dan harga katalog per periode | Struktur standar sponsor. Sumber menyimpan riwayat lengkap dan 77 produk berganti biaya atau harga. Margin harus memakai biaya saat pesanan dibuat |
| `dim_reseller` | Tipe 1 | nama, alamat | Sumber tidak menyimpan riwayat |
| `dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim` | Tipe 1 | nama, grup, tarif | Tabel referensi kecil tanpa riwayat di sumber. Perubahan dianggap perbaikan data |
| `dim_promosi` | Tipe 1 | hampir tidak berubah | Promosi baru muncul sebagai baris baru |
| `dim_tanggal` | Tipe 0 | – | Tidak pernah berubah |

### Contoh SCD tipe 2: José Saraiva

| Versi | wilayah_tugas | berlaku_mulai | berlaku_sampai | is_current | Pesanan reseller |
|-------|---------------|---------------|----------------|------------|------------------|
| 1 | Canada | 2011-05-31 | 2012-05-29 | tidak | 100 |
| 2 | United Kingdom | 2012-05-30 | 9999-12-31 | ya | 171 |

Pesanan tanggal 29 Mei 2012 menunjuk ke versi 1, pesanan tanggal 30 Mei 2012 menunjuk ke versi 2. Kalau memakai tipe 1, seluruh 271 pesanannya akan terlihat sebagai penjualan United Kingdom, dan penjualan Canada tahun 2011 akan salah. Dua orang lain yang pindah: Michael Blythe dan Jillian Carson, yang bertukar Northeast dan Central pada 30 November 2012.

### Contoh SCD tipe 2: Sport-100 Helmet, Red

| Versi | berlaku_mulai | berlaku_sampai | biaya_standar | harga_jual | Baris pesanan reseller |
|-------|---------------|----------------|---------------|------------|------------------------|
| 1 | 2011-05-31 | 2012-05-29 | 12,0278 | 33,6442 | 200 |
| 2 | 2012-05-30 | 2013-05-29 | 13,8782 | 33,6442 | 317 |
| 3 | 2013-05-30 | 9999-12-31 | 13,0863 | 34,9900 | 336 |

Baris pesanan dicocokkan ke versi lewat tanggal pesan. Kalau memakai tipe 1, ke-853 baris itu semua dihitung dengan biaya 13,0863, sehingga margin pesanan 2011 dan 2012 akan salah. Rinciannya di `docs/mapping.md` bagian 2.

---

## 6. Baris "Tidak diketahui"

Setiap dimensi punya satu baris dengan key -1. Kalau baris fakta tidak menemukan pasangannya di dimensi, ia diarahkan ke -1, bukan dibuang atau dikosongkan. Dengan begitu total penjualan tetap cocok dengan sumber. Profil data menunjukkan tidak ada key yang kosong pada data reseller saat ini, tetapi baris ini disiapkan untuk data baru.

---

## 7. Cara memakai star schema

Langkahnya selalu sama: cari **angka** di fakta, cari **sudut pandang** di dimensi, ikuti garisnya.

Contoh P1, *"Berapa nilai penjualan per kategori produk per kuartal?"*:

```sql
SELECT p.kategori, d.tahun, d.kuartal, SUM(f.nilai_penjualan) AS nilai_penjualan
FROM fact_penjualan_reseller f
JOIN dim_produk  p ON p.produk_key  = f.produk_key
JOIN dim_tanggal d ON d.tanggal_key = f.tanggal_pesan_key
GROUP BY p.kategori, d.tahun, d.kuartal;
```

(Kolom `tahun` dan `kuartal` ada di `dim_tanggal` standar, lihat `docs/kamus-data.md`.)

Contoh P3, *"Wilayah mana yang paling besar penjualannya?"*: ikuti `wilayah_key` ke `dim_wilayah`, lalu kelompokkan menurut `grup_wilayah` dan `nama_wilayah`. Contoh P4, *"Promosi mana yang paling banyak memberi diskon, pada kategori apa?"*: ikuti `promosi_key` ke `dim_promosi` dan `produk_key` ke `dim_produk`, lalu jumlahkan `nilai_diskon`.

Kalau sebuah sudut pandang tidak punya garis ke fakta (misalnya "per pelanggan perorangan" atau "per metode pembayaran"), pertanyaan itu tidak bisa dijawab dengan star schema ini.

---

## 8. Pertanyaan yang mungkin diajukan dosen

| Pertanyaan | Jawaban singkat |
|------------|-----------------|
| Apa grain-nya? | Satu produk dalam satu pesanan reseller. 60.919 baris |
| Kenapa dimensinya delapan? | Mengikuti bus matrix kelas: baris Penjualan Reseller bertanda ● pada delapan dimensi. Wilayah, mata uang, dan metode kirim dipakai bersama proses lain, jadi dibuat sebagai dimensi conformed |
| Metode kirim hanya satu nilai, kenapa tetap dimensi? | Dimensi dipakai bersama Penjualan Online dan Pembelian, dan strukturnya harus sama di semua tim. Pesanan reseller memang hanya memakai CARGO TRANSPORT 5, dan itu dinyatakan terbuka di dokumen ini |
| Apa bedanya fakta dan dimensi? | Fakta berisi angka yang dihitung (unit, nilai). Dimensi berisi keterangan untuk mengelompokkan angka itu (siapa, apa, kapan) |
| Kenapa `dim_produk` punya 606 baris padahal produknya 504? | Karena SCD tipe 2: 77 produk punya lebih dari satu versi biaya dan harga. Satu versi = satu baris |
| Kenapa `harga_satuan` tidak dijumlahkan? | Non-aditif: harga dua produk dijumlah tidak bermakna. Ditampilkan sebagai rata-rata |
| Kenapa margin tidak disimpan? | Persentase non-aditif. Dihitung dari dua ukuran aditif saat ditampilkan |
| Apa itu dimensi degeneratif? | Nomor pesanan: sebuah key tanpa atribut lain, jadi disimpan di fakta tanpa tabel sendiri |
| Apa itu role-playing? | Satu tabel `dim_tanggal` dipakai tiga kali (pesan, jatuh tempo, kirim) |
| Kenapa surrogate key? | Karena SCD tipe 2 membuat satu sales person atau satu produk punya beberapa baris, sehingga key asli tidak bisa menjadi primary key |
| Dimensi mana yang tipe 2, dan kenapa? | `dim_sales_person` (3 orang pindah wilayah) dan `dim_produk` untuk biaya dan harga (77 produk berganti, dan margin harus memakai biaya saat pesanan). Dimensi lain tidak punya riwayat atau riwayatnya tidak dianalisis |
| Apa beda wilayah penjualan dan wilayah tugas? | Wilayah penjualan (`dim_wilayah`) mengikuti toko. Wilayah tugas (`dim_sales_person`) mengikuti sales person dan bisa berubah. Berbeda pada 38% pesanan |
| Kenapa ada baris -1? | Supaya baris fakta tidak hilang bila pasangan dimensinya tidak ada |
| Kenapa tidak ada dimensi metode pembayaran? | Tidak ada di bus matrix kelas dan tidak dipakai kelima pertanyaan bisnis. Datanya ada (4 tipe kartu), jadi bisa ditambahkan lewat permintaan perubahan |
