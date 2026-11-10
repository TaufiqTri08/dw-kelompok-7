# Desain Cube dan Wireframe Dashboard

Kelompok : 7
Proses   : Penjualan Reseller
Versi    : 2 (hasil pekan 10)
Dasar    : `docs/desain-star-schema-v1.md`, `docs/mapping.md`, `sql/ddl.sql` (8 dimensi)

Dokumen ini adalah rancangan untuk pekan 13 (cube Mondrian) dan pekan 14 (dashboard). Belum ada yang dibangun. Perubahan setelah desain dikunci memakai permintaan perubahan (`docs/perubahan/CR-xx.md`).

---

## 1. Desain cube

**Nama cube:** `Penjualan Reseller`
**Tabel fakta:** `fact_penjualan_reseller` (60.919 baris)

### 1.1 Dimensi dan hierarki

| Dimensi cube | Tabel | Hierarki dan level | Catatan |
|--------------|-------|--------------------|---------|
| Tanggal Pesan | `dim_tanggal` lewat `tanggal_pesan_key` | Tahun → Kuartal → Bulan → Tanggal | Dimensi bersama |
| Tanggal Jatuh Tempo | `dim_tanggal` lewat `tanggal_jatuh_tempo_key` | sama | Pemakaian ulang dimensi bersama (role-playing) |
| Tanggal Kirim | `dim_tanggal` lewat `tanggal_kirim_key` | sama | Pemakaian ulang dimensi bersama |
| Produk | `dim_produk` | **Kategori** → Subkategori → Produk | Hierarki utama. Level Produk memakai `produk_id` sebagai key (lihat catatan SCD tipe 2 di bawah) |
| Produk | `dim_produk` | **Warna** → Produk | Hierarki kedua |
| Reseller | `dim_reseller` | **Lokasi:** Negara → Provinsi → Kota → Reseller | |
| Reseller | `dim_reseller` | **Tipe Bisnis:** Tipe Bisnis → Reseller | Tambahan, belum dipakai pertanyaan (untuk analisis lanjutan) |
| Sales Person | `dim_sales_person` | Wilayah Tugas → Sales Person | Lihat catatan SCD tipe 2 di bawah |
| Promosi | `dim_promosi` | Jenis Promosi → Promosi | |
| Wilayah | `dim_wilayah` lewat `wilayah_key` | **Grup Wilayah** → Negara → Wilayah | Dimensi bersama. Dipakai P3 |
| Mata Uang | `dim_mata_uang` lewat `mata_uang_key` | Mata Uang | Dimensi bersama. Tambahan, belum dipakai pertanyaan (5 dari 105 kode terpakai) |
| Metode Kirim | `dim_metode_kirim` lewat `metode_key` | Metode Kirim | Dimensi bersama. Tambahan, belum dipakai pertanyaan (hanya CARGO TRANSPORT 5 terpakai) |

Catatan SCD tipe 2 pada Produk: struktur `dim_produk` mengikuti standar sponsor, dengan `biaya_standar` dan `harga_jual` bertipe SCD 2, sehingga satu produk bisa punya beberapa baris (606 baris untuk 504 produk). Level "Produk" memakai `produk_id` sebagai kolom key dan `nama_produk` sebagai nama, supaya total per produk menyatu walaupun biayanya berganti. Level Kategori dan Subkategori tidak terpengaruh karena nilainya sama di semua versi.

Catatan SCD tipe 2 pada Sales Person: satu orang bisa punya beberapa baris (versi). Level "Sales Person" memakai `sales_person_id` sebagai kolom key dan `nama_sales_person` sebagai nama, supaya total per orang menyatu walaupun orang itu pindah wilayah. Level "Wilayah Tugas" memakai `wilayah_tugas` dari versi yang berlaku pada tanggal pesan, sehingga penjualan José Saraiva sebelum 30 Mei 2012 muncul di Canada dan sesudahnya di United Kingdom.

### 1.2 Measure

| Measure | Kolom fakta | Agregasi | Format | Catatan |
|---------|-------------|----------|--------|---------|
| Jumlah Unit | `jumlah_unit` | sum | `#,##0` | |
| Nilai Penjualan | `nilai_penjualan` | sum | `$#,##0.00` | |
| Nilai Diskon | `nilai_diskon` | sum | `$#,##0.00` | |
| Total Biaya Produk | `total_biaya_produk` | sum | `$#,##0.00` | |
| Harga Satuan Rata-rata | `harga_satuan` | avg | `$#,##0.00` | Non-aditif. **Jangan** di-sum |
| Jumlah Pesanan | `nomor_pesanan` | distinct-count | `#,##0` | Dimensi degeneratif, bukan fakta tersimpan |
| Jumlah Baris Pesanan | (baris fakta) | count | `#,##0` | Untuk P5 (21.829 baris di bawah biaya) |

### 1.3 Calculated member

| Nama | Rumus | Alasan dihitung, bukan disimpan |
|------|-------|----------------------------------|
| Margin Kotor | `[Nilai Penjualan] − [Total Biaya Produk]` | Turunan dari dua measure aditif |
| Persentase Margin | `[Margin Kotor] / [Nilai Penjualan]`, hasil kosong jika pembagi 0 | Persentase non-aditif: kalau disimpan per baris lalu dijumlah, hasilnya salah |
| Persentase Diskon | `[Nilai Diskon] / ([Nilai Penjualan] + [Nilai Diskon])` | Sama |
| Rata-rata Nilai per Pesanan | `[Nilai Penjualan] / [Jumlah Pesanan]` | Sama |

Angka uji untuk memastikan cube benar (harus sama dengan rekonsiliasi di `docs/mapping.md` bagian 5): Nilai Penjualan 80.487.704,18; Margin Kotor 476.896,95 (0,59%); Jumlah Pesanan 3.806.

### 1.4 Hal yang harus benar di cube

| Risiko | Penanganan |
|--------|------------|
| Cube menjumlahkan `harga_satuan` | Measure ini diagregasi `avg`, bukan `sum` |
| Pesanan terhitung berkali-kali karena satu pesanan punya banyak baris | Jumlah Pesanan memakai `distinct-count` |
| Orang yang pindah wilayah terhitung dua kali di level Sales Person | Key level memakai `sales_person_id` |
| Produk yang biayanya berganti terhitung beberapa kali di level Produk | Key level memakai `produk_id`, bukan `produk_key` |
| Dimensi tanggal tertukar peran | Tiga dimensi berbeda dengan nama jelas: Tanggal Pesan, Jatuh Tempo, Kirim |
| Pentaho/Mondrian membaca zona waktu berbeda | Cube hanya membaca tabel DW (kolom DATE/INT), sehingga tidak terpengaruh zona waktu sumber |

---

## 2. Wireframe dashboard

Satu halaman, dibaca dari atas ke bawah: ringkasan, lalu satu panel per pertanyaan. Fokus utama sesuai temuan awal adalah P5 (margin tipis dan negatif), jadi diletakkan paling menonjol.

### 2.1 Tata letak

Gambar wireframe: `docs/wireframe-dashboard.png` (sumber `docs/wireframe-dashboard.html`, bisa diedit lalu dirender ulang). Sketsa teks di bawah memuat tata letak yang sama.

```
+---------------------------------------------------------------------------+
| PENJUALAN RESELLER ADVENTURE WORKS            Filter: [Tahun v] [Wilayah v] |
+---------------------------------------------------------------------------+
| KPI:  Nilai Penjualan | Margin Kotor | % Margin | Jumlah Pesanan | Unit    |
|       $80,5 jt        | $0,48 jt     | 0,59%    | 3.806          | 214.516 |
+----------------------------------+----------------------------------------+
| P5  MARGIN PER TAHUN             | P1  NILAI PENJUALAN PER KUARTAL        |
|  Kolom: margin kotor per tahun   |  Garis, satu garis per kategori        |
|  (2013, 2014 negatif)            |  produk, sumbu x = kuartal             |
+----------------------------------+----------------------------------------+
| P5  PRODUK DI BAWAH BIAYA        | P2  SALES PERSON TERBAIK PER TAHUN     |
|  Tabel: produk, margin negatif   |  Batang horizontal, 10 teratas,        |
|  terbesar                        |  pilih tahun lewat filter              |
+----------------------------------+----------------------------------------+
| P3  PENJUALAN PER WILAYAH        | P4  DISKON PER JENIS PROMOSI           |
|  Batang horizontal per wilayah,  |  Batang bertumpuk per kategori         |
|  dikelompokkan grup wilayah      |                                        |
+----------------------------------+----------------------------------------+
```

### 2.2 Rincian panel

| Panel | Pertanyaan | Jenis visual | Measure | Dimensi | Interaksi |
|-------|------------|--------------|---------|---------|-----------|
| KPI | – | Angka besar | Nilai Penjualan, Margin Kotor, % Margin, Jumlah Pesanan, Jumlah Unit | – (mengikuti filter) | Berubah mengikuti filter tahun dan wilayah |
| Margin per tahun | P5 | Diagram kolom, warna berbeda untuk nilai negatif | Margin Kotor | Tanggal Pesan (tahun) | Klik tahun menyaring panel lain |
| Produk di bawah biaya | P5 | Tabel urut menurun | Margin Kotor, Jumlah Baris Pesanan | Produk (kategori, nama produk) | Urut per kolom |
| Penjualan per kuartal | P1 | Diagram garis | Nilai Penjualan | Tanggal Pesan (kuartal), Produk (kategori) | Telusuri kategori ke subkategori |
| Sales person terbaik | P2 | Batang horizontal | Nilai Penjualan, Margin Kotor, Jumlah Pesanan | Sales Person, Tanggal Pesan (tahun) | Filter tahun |
| Penjualan per wilayah | P3 | Batang horizontal | Nilai Penjualan, Jumlah Unit | Wilayah (grup wilayah → negara → wilayah), tahun | Telusuri grup ke wilayah |
| Diskon per promosi | P4 | Batang bertumpuk | Nilai Diskon, Jumlah Unit | Promosi (jenis), Produk (kategori) | Hover menampilkan unit |

### 2.3 Aturan tampilan

- Nilai uang dalam USD dengan label singkat ("$80,5 jt"), nilai lengkap muncul saat hover.
- Margin negatif memakai warna dan tanda minus, tidak hanya warna, supaya terbaca tanpa membedakan warna.
- Tahun 2011 (mulai 31 Mei) dan 2014 (sampai 1 Mei) adalah tahun parsial. Setiap panel yang membandingkan tahun menampilkan catatan "2011 dan 2014 belum penuh setahun".
- Satu filter tahun dan satu filter wilayah berlaku untuk seluruh halaman.

### 2.4 Pertanyaan yang tidak bisa dijawab dashboard ini

| Pertanyaan | Alasan |
|------------|--------|
| Siapa pelanggan perorangan terbaik | Proses ini hanya menjual ke toko. Data perorangan milik proses Penjualan Online |
| Berapa ongkos kirim per pesanan | Ongkos kirim dicatat per pesanan, di luar lingkup v1 |
| Apakah target sales tercapai | Milik proses Kinerja Sales vs Target |

Dua pertanyaan dari usulan awal (reseller terbesar dan porsi penjualan non-USD) dilepas dari lingkup dashboard, lihat `docs/pertanyaan-bisnis.md`. Datanya tetap bisa ditelusuri di cube lewat dimensi Reseller dan Mata Uang (dimensi Mata Uang tetap berisi USD sebagai mata uang nilai di fakta).

---

## 3. Keterhubungan desain (jika satu bagian berubah)

| Jika ini berubah | Yang ikut berubah |
|------------------|-------------------|
| Grain fakta | Seluruh ETL fakta, semua measure cube, semua panel |
| Atribut `dim_sales_person` (SCD tipe 2) | ETL dimensi dan pencarian key fakta, level cube Sales Person, panel P2 |
| Hierarki `dim_produk` | Cube, panel P1, P4, dan P5 |
| Atribut `dim_wilayah` | ETL `dim_wilayah`, level cube Wilayah, panel P3 dan filter wilayah di seluruh halaman |
| Menambah atau menghapus dimensi (misalnya `dim_metode_kirim`) | DDL, mapping, urutan load, staging, cube, diagram, dan bus matrix. Fakta menambah atau menghapus satu kolom key |
| Rumus `total_biaya_produk` | ETL fakta, calculated member margin, panel P2 dan P5 |
