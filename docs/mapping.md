# Source-to-Target Mapping, Strategi SCD, Urutan Load, dan Tabel Staging

Kelompok : 7
Proses   : Penjualan Reseller
Versi    : 2 (hasil pekan 10, dikunci di Steering Review pekan 11/12). Star schema: 8 dimensi + 1 fakta
Sumber   : database `adventureworks2` (hanya dibaca, sesi `SET time_zone = '+05:30'`)
Target   : database `dw_kelompok_7` (tabel di `sql/ddl.sql`)


Perubahan dari v1 (pekan 9) ke v2 (pekan 10) dan desain fisik (pekan 11):

| Perubahan | Alasan |
|-----------|--------|
| `dim_produk` mengikuti **struktur standar sponsor**: 12 kolom, dengan `biaya_standar` dan `harga_jual` bertipe SCD 2 serta kolom `berlaku_mulai`, `berlaku_sampai`, `is_current`. Kolom `ukuran`, `garis_produk`, `model`, `harga_list`, `status_jual` dari v1 dihapus | Catatan sponsor: "sesuaikan `dim_produk` dengan struktur standar". Lima kolom yang dihapus tidak dipakai oleh satu pun dari 5 pertanyaan bisnis |
| `dim_sales_person` memakai SCD tipe 2: ditambah `berlaku_mulai`, `berlaku_sampai`, `is_current` | Tiga sales person pindah wilayah (lihat bagian 2) |
| Strategi SCD: tipe 2 untuk `dim_produk` (biaya, harga) dan `dim_sales_person`, tipe 1 untuk `dim_reseller`, `dim_promosi`, `dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim`, tipe 0 untuk `dim_tanggal` | Keputusan pekan 10 (bagian 2) |
| Delapan dimensi dipertahankan (sama dengan v1): Tanggal, Produk, Reseller, Sales Person, Promosi, Wilayah, Mata Uang, Metode Kirim. Wilayah, mata uang, dan metode kirim berupa tabel sendiri, bukan atribut di `dim_reseller` atau kolom di fakta | Sesuai baris Penjualan Reseller di bus matrix kelas (delapan tanda ●). Ketiganya conformed dengan proses lain (Wilayah dipakai 4 proses, Metode Kirim 3, Mata Uang 2) sehingga penggabungan data antartim memakai dimensi yang sama |
| `dim_tanggal` memakai skrip standar sponsor v1.0 apa adanya (12 kolom, `sql/dim_tanggal_mysql.sql`); kolom perkiraan v1 (hari, bulan, kuartal, tahun) diganti kolom skrip | Catatan sponsor: "gunakan dim_tanggal". Dimensi bersama seluruh kelas |
| Tipe data, constraint, index, baris -1 | Ditetapkan di `sql/ddl.sql` (pekan 11) |

---

## 1. Mapping kolom

### 1.1 Target: dim_produk   (SCD: tipe 0, 1, dan 2 per kolom)
Sumber utama: production.product

Join: `production.productsubcategory`, `production.productcategory`, `production.productcosthistory`, `production.productlistpricehistory`. Hasil: **606 baris versi untuk 504 produk** (77 produk punya lebih dari satu versi) + baris -1.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `produk_key` | INT | - | surrogate key dari DW (AUTO_INCREMENT) | - |
| `produk_id` | INT | product.ProductID | langsung (natural key; bersama `berlaku_mulai` unik) | - |
| `nama_produk` | VARCHAR(50) | product.Name | langsung. Tipe 1: kalau berubah, ditimpa di semua versi produk itu | - |
| `nomor_produk` | VARCHAR(25) | product.ProductNumber | langsung. Tipe 0: tidak pernah diubah | - |
| `warna` | VARCHAR(15) | product.Color | langsung. Tipe 1 | NULL → "Tidak ada" (28 dari 250 produk yang terjual) |
| `subkategori` | VARCHAR(50) | productsubcategory.Name | join lewat `product.ProductSubcategoryID`. Tipe 1 | NULL → "Tanpa kategori" (209 dari 504 produk, tidak ada yang terjual) |
| `kategori` | VARCHAR(50) | productcategory.Name | join lewat `productsubcategory.ProductCategoryID`. Tipe 1 | NULL → "Tanpa kategori" |
| `biaya_standar` | DECIMAL(12,4) | productcosthistory.StandardCost | nilai pada periode yang bersangkutan. Tipe 2. Produk tanpa riwayat memakai `product.StandardCost` | NULL → 0 |
| `harga_jual` | DECIMAL(12,4) | productlistpricehistory.ListPrice | nilai pada periode yang bersangkutan. Tipe 2. Produk tanpa riwayat memakai `product.ListPrice` | NULL → 0 |
| `berlaku_mulai` | DATE | productcosthistory.StartDate | `DATE(StartDate)`. Produk tanpa riwayat: `DATE(product.SellStartDate)` | - |
| `berlaku_sampai` | DATE | productcosthistory.EndDate | `DATE(EndDate)`. NULL → `9999-12-31`. Periode terakhir yang sudah ditutup di sumber juga diperpanjang ke `9999-12-31` (lihat bawah) | NULL → 9999-12-31 |
| `is_current` | BOOLEAN | - | `berlaku_sampai = '9999-12-31'` | - |

Aturan pembentukan versi (semuanya dibuktikan oleh `sql/uji-dim-produk-scd2.sql`):

1. **Satu baris riwayat = satu versi.** Riwayat biaya (395 baris, 293 produk) dan riwayat harga (395 baris) punya periode yang persis sama (tanggal mulai dan akhir sama), jadi keduanya digabung lewat `ProductID` dan `StartDate`.
2. **Periode terakhir yang tertutup diperpanjang.** Di sumber, 98 produk punya periode terakhir yang sudah ditutup (paling lambat 2013-05-29), padahal pesanan reseller berlanjut sampai 2014-05-01. Biaya dan harga di `production.product` untuk 98 produk itu sama persis dengan periode terakhirnya, artinya tidak ada perubahan. Tanpa perpanjangan, 64 baris pesanan (25 produk) tidak menemukan versi.
3. **Produk tanpa riwayat** (211 produk, tidak ada yang terjual ke reseller) menjadi satu versi dari `production.product`. 200 di antaranya memang berbiaya dan berharga 0 di sumber (komponen).
4. **Baris -1** (`produk_id` -1, mulai `1900-01-01`, sampai `9999-12-31`) dibuat oleh `ddl.sql`.

Query Table input di Pentaho (juga dipakai di `sql/uji-dim-produk-scd2.sql`):

```sql
SELECT p.ProductID AS produk_id, p.Name AS nama_produk, p.ProductNumber AS nomor_produk,
       COALESCE(p.Color, 'Tidak ada') AS warna,
       COALESCE(sc.Name, 'Tanpa kategori') AS subkategori,
       COALESCE(pc.Name, 'Tanpa kategori') AS kategori,
       COALESCE(ch.StandardCost, 0) AS biaya_standar,
       COALESCE(ph.ListPrice, 0) AS harga_jual,
       DATE(ch.StartDate) AS berlaku_mulai,
       CASE WHEN ch.EndDate IS NULL
              OR ch.StartDate = (SELECT MAX(z.StartDate) FROM production_productcosthistory z WHERE z.ProductID = ch.ProductID)
            THEN DATE('9999-12-31') ELSE DATE(ch.EndDate) END AS berlaku_sampai
FROM production_product p
JOIN production_productcosthistory      ch ON ch.ProductID = p.ProductID
JOIN production_productlistpricehistory ph ON ph.ProductID = ch.ProductID AND ph.StartDate = ch.StartDate
LEFT JOIN production_productsubcategory sc ON sc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN production_productcategory    pc ON pc.ProductCategoryID = sc.ProductCategoryID
UNION ALL
SELECT p.ProductID, p.Name, p.ProductNumber, COALESCE(p.Color, 'Tidak ada'),
       COALESCE(sc.Name, 'Tanpa kategori'), COALESCE(pc.Name, 'Tanpa kategori'),
       COALESCE(p.StandardCost, 0), COALESCE(p.ListPrice, 0), DATE(p.SellStartDate), DATE('9999-12-31')
FROM production_product p
LEFT JOIN production_productsubcategory sc ON sc.ProductSubcategoryID = p.ProductSubcategoryID
LEFT JOIN production_productcategory    pc ON pc.ProductCategoryID = sc.ProductCategoryID
WHERE p.ProductID NOT IN (SELECT ProductID FROM production_productcosthistory)
```

Kategori dan subkategori diratakan ke dalam satu tabel dimensi: empat tabel sumber menjadi satu (denormalisasi).

### 1.2 Target: dim_reseller   (SCD: tipe 1)
Sumber utama: sales.store

Join: `person.businessentityaddress`, `person.address`, `person.stateprovince`, `person.countryregion`. Hasil: 701 toko + baris -1. Wilayah penjualan toko tidak disimpan di sini, tetapi di `dim_wilayah` (bagian 1.6).

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `reseller_key` | INT | - | surrogate key dari DW | - |
| `reseller_id` | INT | store.BusinessEntityID | langsung (natural key, unik) | - |
| `nama_reseller` | VARCHAR(50) | store.Name | langsung | - |
| `tipe_bisnis` | VARCHAR(30) | store.Demographics (XML) → BusinessType | `SUBSTRING_INDEX` pada teks XML. BM → Value Added Reseller, BS → Specialty Bike Shop, OS → Warehouse | kosong → "Tidak diketahui" |
| `spesialisasi` | VARCHAR(20) | store.Demographics (XML) → Specialty | `SUBSTRING_INDEX` pada teks XML | kosong → "Tidak diketahui" |
| `tahun_buka` | INT | store.Demographics (XML) → YearOpened | diubah ke angka | kosong → -1 |
| `jumlah_karyawan` | INT | store.Demographics (XML) → NumberEmployees | diubah ke angka | kosong → -1 |
| `kota` | VARCHAR(30) | address.City | alamat bertipe Main Office (`businessentityaddress.AddressTypeID`) | kosong → "Tidak diketahui" |
| `provinsi` | VARCHAR(50) | stateprovince.Name | join lewat `address.StateProvinceID` | kosong → "Tidak diketahui" |
| `negara` | VARCHAR(50) | countryregion.Name | join lewat `stateprovince.CountryRegionCode` | kosong → "Tidak diketahui" |

### 1.3 Target: dim_sales_person   (SCD: tipe 2)
Sumber utama: sales.salesperson

Join: `sales.salesterritoryhistory`, `sales.salesterritory`, `person.person`, `humanresources.employee`. Satu baris per sales person per periode wilayah tugas. 14 orang punya riwayat wilayah (17 periode), 3 manajer tanpa riwayat (1 baris masing-masing): **20 baris** + baris -1.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `sales_person_key` | INT | - | surrogate key dari DW | - |
| `sales_person_id` | INT | salesperson.BusinessEntityID | langsung (natural key; bersama `berlaku_mulai` unik) | - |
| `nama_sales_person` | VARCHAR(150) | person.FirstName, person.LastName | `CONCAT(FirstName, ' ', LastName)` | - |
| `jabatan` | VARCHAR(50) | employee.JobTitle | langsung | - |
| `wilayah_tugas` | VARCHAR(50) | salesterritory.Name | lewat `salesterritoryhistory.TerritoryID`. Satu baris per periode | manajer tanpa riwayat → "Tidak ada wilayah" |
| `persen_komisi` | DECIMAL(6,4) | salesperson.CommissionPct | langsung | - |
| `berlaku_mulai` | DATE | salesterritoryhistory.StartDate | `DATE(StartDate)` | manajer tanpa riwayat → 1900-01-01 |
| `berlaku_sampai` | DATE | salesterritoryhistory.EndDate | `DATE(EndDate)` | NULL → 9999-12-31 |
| `is_current` | BOOLEAN | - | `berlaku_sampai = '9999-12-31'` | - |

### 1.4 Target: dim_promosi   (SCD: tipe 1)
Sumber utama: sales.specialoffer

16 promosi (termasuk "No Discount") + baris -1.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `promosi_key` | INT | - | surrogate key dari DW | - |
| `promosi_id` | INT | specialoffer.SpecialOfferID | langsung (natural key, unik) | - |
| `nama_promosi` | VARCHAR(255) | specialoffer.Description | langsung | - |
| `jenis_promosi` | VARCHAR(50) | specialoffer.Type | langsung | - |
| `kategori_promosi` | VARCHAR(50) | specialoffer.Category | langsung | - |
| `persen_diskon` | DECIMAL(6,4) | specialoffer.DiscountPct | langsung | - |
| `tanggal_mulai` | DATE | specialoffer.StartDate | `DATE(StartDate)` | - |
| `tanggal_selesai` | DATE | specialoffer.EndDate | `DATE(EndDate)` | - |
| `qty_min` | INT | specialoffer.MinQty | langsung | - |
| `qty_maks` | INT | specialoffer.MaxQty | langsung | NULL → -1 (tanpa batas atas) |

### 1.5 Target: dim_tanggal   (SCD: tipe 0)
Sumber utama: tidak ada tabel sumber. Dipasang dari `sql/dim_tanggal_mysql.sql` (skrip standar sponsor v1.0, butuh MySQL 8.0+), tidak diubah. Kolom dibangkitkan oleh skrip dari deretan tanggal.

2.192 baris: 2.191 hari (1 Januari 2010 sampai 31 Desember 2015) + baris `tanggal_key = -1`. Fakta merujuknya tiga kali lewat `tanggal_key` berformat YYYYMMDD (tanggal pesan, jatuh tempo, kirim). Tidak ada kolom yang dimapping dari AdventureWorks, jadi ETL pekan depan cukup menghitung `DATE_FORMAT(OrderDate, '%Y%m%d')` untuk mengisi key di fakta.

| Kolom target | Tipe | Sumber | Transformasi di skrip | Aturan NULL |
|--------------|------|--------|-----------------------|-------------|
| `tanggal_key` | INT | - (dibangkitkan) | `DATE_FORMAT(d, '%Y%m%d')` sebagai angka | -1 untuk tidak diketahui |
| `tanggal` | DATE | - | satu baris per hari, UNIQUE | baris -1 = 1900-01-01 |
| `tahun` | INT | - | `YEAR(d)` | baris -1 = 0 |
| `semester` | INT | - | 1 bila bulan ≤ 6, selain itu 2 | baris -1 = 0 |
| `kuartal` | INT | - | `QUARTER(d)` | baris -1 = 0 |
| `bulan` | INT | - | `MONTH(d)` | baris -1 = 0 |
| `nama_bulan` | VARCHAR(15) | - | `ELT(MONTH(d), 'Januari', ... 'Desember')` | baris -1 = Tidak diketahui |
| `minggu_dalam_tahun` | INT | - | `WEEK(d, 3)` (minggu ISO 8601) | baris -1 = 0 |
| `tanggal_dalam_bulan` | INT | - | `DAY(d)` | baris -1 = 0 |
| `hari_dalam_minggu` | INT | - | `WEEKDAY(d) + 1` (Senin = 1) | baris -1 = 0 |
| `nama_hari` | VARCHAR(15) | - | `ELT(WEEKDAY(d) + 1, 'Senin', ... 'Minggu')` | baris -1 = Tidak diketahui |
| `is_akhir_pekan` | BOOLEAN | - | `WEEKDAY(d) >= 5` (Sabtu dan Minggu) | baris -1 = 0 |

Urutan pemasangan: skrip ini dijalankan **sebelum** `sql/ddl.sql`. Skrip memakai `DROP TABLE IF EXISTS dim_tanggal`, yang sengaja gagal bila fakta sudah merujuknya. Untuk memasang ulang, hapus dulu `fact_penjualan_reseller` (atau jalankan ulang seluruh database), lalu jalankan skrip ini dan `ddl.sql`.

### 1.6 Target: dim_wilayah   (SCD: tipe 1)
Sumber utama: sales.salesterritory

Join: `person.countryregion` (nama negara). 10 wilayah penjualan + baris -1. Seluruh 10 wilayah dipakai oleh pesanan reseller.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `wilayah_key` | INT | - | surrogate key dari DW | - |
| `wilayah_id` | INT | salesterritory.TerritoryID | langsung (natural key, unik) | - |
| `nama_wilayah` | VARCHAR(50) | salesterritory.Name | langsung (mis. Southeast, Canada) | - |
| `kode_negara` | VARCHAR(3) | salesterritory.CountryRegionCode | langsung (US, CA, FR, DE, AU, GB) | - |
| `nama_negara` | VARCHAR(50) | countryregion.Name | join lewat `salesterritory.CountryRegionCode` | kosong → "Tidak diketahui" (tidak ada kasusnya) |
| `grup_wilayah` | VARCHAR(50) | salesterritory.`Group` | langsung (`Group` perlu backtick di MySQL). Nilai: North America, Europe, Pacific | - |

Fakta memakai wilayah dari `h.TerritoryID`. Nilainya sama dengan wilayah toko pada 3.806 dari 3.806 pesanan (diuji di `sql/uji-dim-wilayah-mata-uang-metode.sql`). `wilayah_tugas` di `dim_sales_person` adalah hal yang berbeda: wilayah tempat sales person bertugas pada periode tertentu (SCD tipe 2).

Query Table input di Pentaho:

```sql
SELECT t.TerritoryID AS wilayah_id, t.Name AS nama_wilayah, t.CountryRegionCode AS kode_negara,
       c.Name AS nama_negara, t.`Group` AS grup_wilayah
FROM sales_salesterritory t
JOIN person_countryregion c ON c.CountryRegionCode = t.CountryRegionCode
```

### 1.7 Target: dim_mata_uang   (SCD: tipe 1)
Sumber utama: sales.currency

105 mata uang + baris -1. Pesanan reseller hanya memakai 5 di antaranya (USD, CAD, GBP, EUR, AUD). Semua kode dimuat supaya dimensi sama dengan tim lain.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `mata_uang_key` | INT | - | surrogate key dari DW | - |
| `kode_mata_uang` | CHAR(3) | currency.CurrencyCode | langsung (kode ISO, natural key, unik) | - |
| `nama_mata_uang` | VARCHAR(100) | currency.Name | langsung (mis. US Dollar) | - |

Mata uang pesanan dicari lewat `h.CurrencyRateID` → `currencyrate.ToCurrencyCode`. Kurs kosong berarti transaksi dalam USD (2.629 pesanan). Seluruh nilai uang di fakta tetap dalam USD, jadi dimensi ini menjawab "transaksi memakai mata uang apa", bukan mengubah angka.

### 1.8 Target: dim_metode_kirim   (SCD: tipe 1)
Sumber utama: purchasing.shipmethod

5 metode kirim + baris -1. Semua 3.806 pesanan reseller memakai satu metode: CARGO TRANSPORT 5. Empat metode lain tetap dimuat karena dimensi ini dipakai bersama proses Penjualan Online dan Pembelian.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `metode_key` | INT | - | surrogate key dari DW | - |
| `metode_id` | INT | shipmethod.ShipMethodID | langsung (natural key, unik) | - |
| `nama_metode` | VARCHAR(50) | shipmethod.Name | langsung | - |
| `tarif_dasar` | DECIMAL(12,4) | shipmethod.ShipBase | langsung | - |
| `tarif_per_kg` | DECIMAL(12,4) | shipmethod.ShipRate | langsung | - |

### 1.9 Target: fact_penjualan_reseller   (grain: satu produk dalam satu pesanan reseller)
Sumber utama: sales.salesorderdetail (d)

Digabung dengan `sales.salesorderheader` (h) yang `OnlineOrderFlag = 0`. Hasil: **60.919 baris**.

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
|--------------|------|--------------------|--------------|-------------|
| `nomor_pesanan` | VARCHAR(25) | h.SalesOrderNumber | langsung (degenerate dimension) | - |
| `nomor_baris_pesanan` | INT | d.SalesOrderDetailID | langsung (degenerate dimension) | - |
| `nomor_po_reseller` | VARCHAR(25) | h.PurchaseOrderNumber | langsung (degenerate dimension) | boleh NULL |
| `tanggal_pesan_key` | INT | h.OrderDate | tanggal ke YYYYMMDD: `YEAR*10000 + MONTH*100 + DAY` (setelah `SET time_zone = '+05:30'`) | -1 |
| `tanggal_jatuh_tempo_key` | INT | h.DueDate | tanggal ke YYYYMMDD | -1 |
| `tanggal_kirim_key` | INT | h.ShipDate | tanggal ke YYYYMMDD | -1 |
| `produk_key` | INT | d.ProductID, h.OrderDate | cari di `dim_produk` dengan `produk_id = ProductID` **dan** `DATE(OrderDate)` di antara `berlaku_mulai` dan `berlaku_sampai` | -1 |
| `reseller_key` | INT | h.CustomerID → customer.StoreID | cari di `dim_reseller.reseller_id` | -1 |
| `sales_person_key` | INT | h.SalesPersonID, h.OrderDate | cari di `dim_sales_person` dengan `sales_person_id = SalesPersonID` **dan** `DATE(OrderDate)` di antara `berlaku_mulai` dan `berlaku_sampai` | -1 |
| `promosi_key` | INT | d.SpecialOfferID | cari di `dim_promosi.promosi_id` | -1 |
| `wilayah_key` | INT | h.TerritoryID | cari di `dim_wilayah.wilayah_id` | -1 (tidak ada kasusnya) |
| `mata_uang_key` | INT | h.CurrencyRateID → currencyrate.ToCurrencyCode | cari di `dim_mata_uang.kode_mata_uang` dengan `COALESCE(ToCurrencyCode, 'USD')` | kurs kosong (2.629 pesanan) → USD |
| `metode_key` | INT | h.ShipMethodID | cari di `dim_metode_kirim.metode_id` | -1 (tidak ada kasusnya) |
| `jumlah_unit` | INT | d.OrderQty | langsung | - |
| `nilai_penjualan` | DECIMAL(14,4) | d.OrderQty, d.UnitPrice, d.UnitPriceDiscount | `OrderQty * UnitPrice * (1 - UnitPriceDiscount)` | - |
| `nilai_diskon` | DECIMAL(14,4) | d.OrderQty, d.UnitPrice, d.UnitPriceDiscount | `OrderQty * UnitPrice * UnitPriceDiscount` | - |
| `total_biaya_produk` | DECIMAL(14,4) | d.OrderQty, dim_produk.biaya_standar | `OrderQty * biaya_standar` dari versi `dim_produk` yang ditemukan untuk `produk_key` | - |
| `harga_satuan` | DECIMAL(14,4) | d.UnitPrice | langsung (harga saat transaksi) | - |

Catatan pencarian key: setiap baris fakta harus menemukan **tepat satu** versi produk dan **tepat satu** versi sales person. Uji di `sql/uji-dim-produk-scd2.sql` bagian 3 (versi produk: 60.919 baris, 0 tanpa versi, 0 dengan lebih dari satu versi). Untuk wilayah, mata uang, dan metode kirim, `sql/uji-dim-wilayah-mata-uang-metode.sql` membuktikan 60.919 dari 60.919 baris menemukan key di ketiganya.

## Urutan load

1. Pasang `dim_tanggal` standar v1.0, lalu jalankan `sql/ddl.sql` (fakta merujuk dimensi, jadi tabelnya harus ada lebih dulu).
2. Staging: kosongkan semua tabel `stg_*`, lalu salin dari sumber lewat koneksi sumber ke koneksi DW (staging selalu dimulai dari kosong).
3. Dimensi tipe 1: `dim_reseller`, `dim_promosi`, `dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim` (tidak saling bergantung, urutan bebas).
4. Dimensi tipe 2: `dim_produk` dan `dim_sales_person` (dibangun dari riwayat di sumber, harus lengkap sebelum fakta).
5. Fakta: `fact_penjualan_reseller` (semua key dicari ke dimensi yang sudah terisi).
6. Rekonsiliasi (bagian 5): membuktikan data benar sebelum dipakai cube dan dashboard.

Perilaku jika ETL dijalankan ulang: dimensi tipe 1 memakai insert/update berdasarkan natural key (tidak menambah baris ganda). Fakta dikosongkan lebih dulu, lalu dimensi tipe 2 dihapus (kecuali baris -1) dan dibangun ulang dari riwayat sumber, lalu fakta diisi lagi. Primary key `(nomor_pesanan, nomor_baris_pesanan)` mencegah duplikat jika fakta lupa dikosongkan.

---

## 2. Strategi SCD per dimensi

| Dimensi | Tipe | Atribut yang bisa berubah | Alasan |
|---------|------|---------------------------|--------|
| `dim_produk` | **Tipe 2** (`biaya_standar`, `harga_jual`), tipe 1 (nama, warna, subkategori, kategori), tipe 0 (`nomor_produk`) | biaya standar dan harga jual per periode | Struktur standar sponsor. Sumber menyimpan riwayat lengkap (`productcosthistory`, `productlistpricehistory`), dan 77 produk berganti biaya atau harga. Margin (P5) harus dihitung dengan biaya saat pesanan dibuat. Atribut deskriptif tidak punya riwayat yang dianalisis, jadi cukup ditimpa |
| `dim_sales_person` | **Tipe 2** | `wilayah_tugas` | Data membuktikan perubahan terjadi: 3 sales person pindah wilayah. Analisis kinerja per wilayah (P2, P3) harus memakai wilayah saat pesanan dibuat, bukan wilayah terbaru. Riwayat tersedia lengkap di `sales_salesterritoryhistory` |
| `dim_reseller` | Tipe 1 | nama, alamat, jumlah karyawan | Sumber hanya menyimpan keadaan terbaru, tidak ada riwayat yang bisa dibangun. Analisis lokasi toko memakai alamat terbaru |
| `dim_wilayah` | Tipe 1 | nama wilayah, grup wilayah | Sepuluh wilayah tetap, tidak ada riwayat di sumber. Wilayah toko dan wilayah pesanan sama pada 3.806 dari 3.806 pesanan, sehingga tidak perlu versi |
| `dim_mata_uang` | Tipe 1 | nama mata uang | Kode ISO tidak berubah, hanya nama yang mungkin diperbaiki penulisannya |
| `dim_metode_kirim` | Tipe 1 | tarif dasar, tarif per kg | Sumber hanya menyimpan tarif terbaru, tidak ada riwayat tarif. Nilai uang di fakta tidak memakai tarif ini, jadi perubahan tarif tidak mengubah angka yang dianalisis |
| `dim_promosi` | Tipe 1 | hampir tidak berubah | Promosi baru muncul sebagai baris baru. Masa berlakunya adalah atribut, bukan riwayat perubahan |
| `dim_tanggal` | Tipe 0 | - | Tabel standar dari sponsor. Tanggal tidak pernah berubah, jadi tidak ada proses pembaruan |

Tipe per kolom penting di `dim_produk`:

| Kolom | Tipe | Alasan |
|-------|------|--------|
| `nomor_produk` | 0 | Kode produk tidak pernah diubah setelah dibuat |
| `nama_produk`, `warna`, `subkategori`, `kategori` | 1 | Perbaikan penulisan atau penataan ulang kategori. Laporan lama sebaiknya ikut memakai nama terbaru |
| `biaya_standar` | 2 | Biaya berubah tiap tahun. Margin per pesanan harus memakai biaya pada tanggal pesan. Angka 14.387 baris di profil data terdiri dari 14.323 baris yang biaya periodenya memang berbeda dengan biaya terbaru, ditambah 64 baris yang jatuh setelah periode terakhir (biayanya sama dengan biaya terbaru) |
| `harga_jual` | 2 | Harga katalog berubah (misalnya Sport-100 Helmet, Red: 33,6442 menjadi 34,99 pada 2013-05-30), sehingga harga pesanan dapat dibandingkan dengan harga katalog saat itu |

### Contoh SCD tipe 2 dengan data nyata: Sport-100 Helmet, Red (produk 707)

| produk_key | berlaku_mulai | berlaku_sampai | biaya_standar | harga_jual | is_current | Baris pesanan reseller |
|------------|---------------|----------------|---------------|------------|------------|------------------------|
| (versi 1) | 2011-05-31 | 2012-05-29 | 12,0278 | 33,6442 | tidak | 200 |
| (versi 2) | 2012-05-30 | 2013-05-29 | 13,8782 | 33,6442 | tidak | 317 |
| (versi 3) | 2013-05-30 | 9999-12-31 | 13,0863 | 34,9900 | ya | 336 |

Satu produk, tiga versi, tiga `produk_key`. Pesanan 2012-05-29 menunjuk ke versi 1, pesanan 2012-05-30 ke versi 2. Karena itu di cube level Produk memakai `produk_id` sebagai key dan nama sebagai caption, supaya total per produk menyatu.

### Contoh SCD tipe 2 dengan data nyata: José Saraiva (id 282)

| sales_person_key | wilayah_tugas | berlaku_mulai | berlaku_sampai | is_current | Jumlah pesanan reseller |
|------------------|---------------|---------------|----------------|------------|-------------------------|
| (versi 1) | Canada | 2011-05-31 | 2012-05-29 | tidak | 100 |
| (versi 2) | United Kingdom | 2012-05-30 | 9999-12-31 | ya | 171 |

Pesanan tanggal 2012-05-29 menunjuk ke versi 1, pesanan tanggal 2012-05-30 menunjuk ke versi 2. Dua orang lain yang pindah: Michael Blythe (275, Northeast → Central pada 2012-11-30) dan Jillian Carson (277, Central → Northeast pada 2012-11-30).

---

## 3. Urutan load, rinci

| Langkah | Isi | Alasan urutan |
|---------|-----|---------------|
| 0 | Pasang `dim_tanggal` standar v1.0, lalu jalankan `sql/ddl.sql` | Fakta merujuk dimensi |
| 1 | Kosongkan tabel staging, lalu salin dari sumber (koneksi sumber → koneksi DW) | Staging selalu dimulai dari kosong |
| 2 | Load dimensi tipe 1: `dim_reseller`, `dim_promosi`, `dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim` | Tidak saling bergantung, urutan bebas |
| 3 | Load dimensi tipe 2: `dim_produk` (query bagian 1.1), `dim_sales_person` | Dibuat dari riwayat sumber, harus lengkap sebelum fakta |
| 4 | Load `fact_penjualan_reseller` | Semua key dicari ke dimensi yang sudah terisi |
| 5 | Rekonsiliasi (bagian 5) | Membuktikan data benar sebelum dipakai cube dan dashboard |

---

## 4. Daftar tabel staging

Tabel dibuat di pekan 12 lewat Pentaho (tombol SQL pada langkah Table Output). Isinya salinan mentah, tanpa constraint, dikosongkan setiap ETL. Jumlahnya 22.

| Tabel staging | Sumber | Dipakai untuk |
|---------------|--------|---------------|
| `stg_salesorderheader` | `sales_salesorderheader` (hanya `OnlineOrderFlag = 0`) | Fakta |
| `stg_salesorderdetail` | `sales_salesorderdetail` | Fakta |
| `stg_customer` | `sales_customer` | Fakta (pencarian `reseller_key` lewat `StoreID`) |
| `stg_store` | `sales_store` | `dim_reseller` |
| `stg_businessentityaddress`, `stg_address`, `stg_stateprovince`, `stg_countryregion` | `person_businessentityaddress`, `person_address`, `person_stateprovince`, `person_countryregion` | `dim_reseller` (alamat toko), `dim_wilayah` (`stg_countryregion`: nama negara) |
| `stg_salesperson` | `sales_salesperson` | `dim_sales_person` |
| `stg_salesterritoryhistory` | `sales_salesterritoryhistory` | `dim_sales_person` (SCD tipe 2) |
| `stg_salesterritory` | `sales_salesterritory` | `dim_wilayah`, `dim_sales_person` |
| `stg_person`, `stg_employee` | `person_person`, `humanresources_employee` | `dim_sales_person` |
| `stg_product`, `stg_productsubcategory`, `stg_productcategory` | `production_product`, `production_productsubcategory`, `production_productcategory` | `dim_produk` |
| `stg_productcosthistory` | `production_productcosthistory` | `dim_produk` (`biaya_standar`, SCD tipe 2) |
| `stg_productlistpricehistory` | `production_productlistpricehistory` | `dim_produk` (`harga_jual`, SCD tipe 2) |
| `stg_specialoffer` | `sales_specialoffer` | `dim_promosi` |
| `stg_currencyrate` | `sales_currencyrate` | Fakta (`mata_uang_key`) |
| `stg_currency` | `sales_currency` | `dim_mata_uang` |
| `stg_shipmethod` | `purchasing_shipmethod` | `dim_metode_kirim`, fakta (`metode_key`) |

Catatan: kolom TIMESTAMP seperti `OrderDate` dibaca dengan zona waktu sesi +05:30 di koneksi sumber Pentaho. Tanggal sudah benar saat masuk staging. Kolom `StartDate` dan `EndDate` di tabel riwayat produk bertipe DATETIME dan tidak bergeser.

---

## 5. Rekonsiliasi setelah load

Angka acuan dari profil data dan dari `sql/uji-dim-produk-scd2.sql`. Semua harus cocok sebelum ETL dinyatakan benar.

| Pemeriksaan | Nilai yang diharapkan |
|-------------|-----------------------|
| `COUNT(*)` di `fact_penjualan_reseller` | 60.919 |
| `COUNT(DISTINCT nomor_pesanan)` | 3.806 |
| `SUM(nilai_penjualan)` | 80.487.704,18 |
| `SUM(nilai_diskon)` | 527.507,91 |
| `SUM(jumlah_unit)` | 214.516 |
| `SUM(nilai_penjualan) - SUM(total_biaya_produk)` | 476.896,95 |
| Baris fakta yang memakai key -1 di dimensi mana pun | 0 |
| `MIN`/`MAX` tanggal pesan | 2011-05-31 / 2014-05-01 |
| Baris `dim_produk` (tanpa -1) | 606 (504 produk, 77 di antaranya punya lebih dari satu versi) |
| Produk dengan tepat satu versi berlaku sekarang (`berlaku_sampai = 9999-12-31`) | 504 dari 504 |
| Baris `dim_wilayah`, `dim_mata_uang`, `dim_metode_kirim` (tanpa -1) | 10, 105, 5 |
| Pesanan per mata uang (`mata_uang_key`) | USD 2.629, CAD 692, GBP 188, EUR 172, AUD 125 (jumlah 3.806) |
| Pesanan per metode kirim | CARGO TRANSPORT 5: 3.806, empat metode lain 0 |
| `SUM(nilai_penjualan)` per grup wilayah | North America 67.985.726,79 (3.166 pesanan), Europe 10.907.642,01 (515), Pacific 1.594.335,37 (125). Jumlahnya 80.487.704,18, boleh berselisih 0,01 karena pembulatan |
| Baris `dim_sales_person` (tanpa -1) | 20 |
| Porsi nilai penjualan dengan mata uang (`mata_uang_key`) bukan USD | 28,3% |
| Jumlah baris `dim_reseller` (tanpa -1) | 701 |
| Pesanan José Saraiva per versi | 100 (Canada) dan 171 (United Kingdom) |
| Baris pesanan Sport-100 Helmet, Red per versi `dim_produk` | 200, 317, 336 |
