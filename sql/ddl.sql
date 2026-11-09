-- ddl.sql | MySQL/MariaDB (XAMPP) | Kelompok X | Penjualan Reseller | Star schema v2 (8 dimensi)
--
-- Dijalankan di database DW (misalnya dw_kelompok_x), BUKAN di database sumber adventureworks2.
-- Jalankan SETELAH dim_tanggal standar v1.0 terpasang (dim_tanggal tidak dibuat dan tidak dihapus di sini).
-- Bisa dijalankan berulang kali: urutan DROP dibalik (fakta dulu), semua memakai IF EXISTS.
--
-- Catatan MySQL:
--  * Foreign key ditulis sebagai CONSTRAINT ... FOREIGN KEY di bawah tabel.
--    "REFERENCES" di samping kolom diabaikan MySQL/MariaDB tanpa error.
--  * Surrogate key memakai INT AUTO_INCREMENT. Baris -1 diisi manual, dan nomor urut berikutnya mulai dari 1.
--  * Semua tabel InnoDB (satu-satunya mesin yang menegakkan foreign key).

SET FOREIGN_KEY_CHECKS = 1;

-- 1. Hapus dengan urutan terbalik: fakta dulu, lalu dimensi
DROP TABLE IF EXISTS fact_penjualan_reseller;
DROP TABLE IF EXISTS dim_metode_kirim;
DROP TABLE IF EXISTS dim_mata_uang;
DROP TABLE IF EXISTS dim_wilayah;
DROP TABLE IF EXISTS dim_promosi;
DROP TABLE IF EXISTS dim_sales_person;
DROP TABLE IF EXISTS dim_reseller;
DROP TABLE IF EXISTS dim_produk;

-- 2. Dimensi ----------------------------------------------------------------

-- Struktur standar dari sponsor (pertemuan 10, dim_produk).
-- SCD campuran: nomor_produk tipe 0; nama_produk, warna, subkategori, kategori tipe 1;
-- biaya_standar dan harga_jual tipe 2. Karena itu satu produk bisa punya beberapa baris (satu per periode biaya/harga).
-- Fakta mencari produk_key dengan produk_id DAN tanggal pesan di antara berlaku_mulai dan berlaku_sampai.
CREATE TABLE dim_produk (
  produk_key      INT           NOT NULL AUTO_INCREMENT,
  produk_id       INT           NOT NULL,
  nama_produk     VARCHAR(50)   NOT NULL,
  nomor_produk    VARCHAR(25)   NOT NULL,
  warna           VARCHAR(15)   NOT NULL,
  subkategori     VARCHAR(50)   NOT NULL,
  kategori        VARCHAR(50)   NOT NULL,
  biaya_standar   DECIMAL(12,4) NOT NULL,
  harga_jual      DECIMAL(12,4) NOT NULL,
  berlaku_mulai   DATE          NOT NULL,
  berlaku_sampai  DATE          NOT NULL,
  is_current      BOOLEAN       NOT NULL,
  PRIMARY KEY (produk_key),
  CONSTRAINT uq_produk_versi UNIQUE (produk_id, berlaku_mulai),
  CONSTRAINT ck_produk_periode CHECK (berlaku_mulai <= berlaku_sampai)
) ENGINE=InnoDB;

-- SCD tipe 1. Dimensi khusus tim reseller.
-- Hanya membawa lokasi kantor toko (kota, provinsi, negara). Wilayah penjualan ada di dim_wilayah.
CREATE TABLE dim_reseller (
  reseller_key    INT          NOT NULL AUTO_INCREMENT,
  reseller_id     INT          NOT NULL,
  nama_reseller   VARCHAR(50)  NOT NULL,
  tipe_bisnis     VARCHAR(30)  NOT NULL,
  spesialisasi    VARCHAR(20)  NOT NULL,
  tahun_buka      INT          NOT NULL,      -- -1 = tidak diketahui
  jumlah_karyawan INT          NOT NULL,      -- -1 = tidak diketahui
  kota            VARCHAR(30)  NOT NULL,
  provinsi        VARCHAR(50)  NOT NULL,
  negara          VARCHAR(50)  NOT NULL,
  PRIMARY KEY (reseller_key),
  CONSTRAINT uq_reseller_id UNIQUE (reseller_id)
) ENGINE=InnoDB;

-- SCD tipe 2: satu sales person bisa punya beberapa baris, satu per periode wilayah tugas.
CREATE TABLE dim_sales_person (
  sales_person_key  INT          NOT NULL AUTO_INCREMENT,
  sales_person_id   INT          NOT NULL,
  nama_sales_person VARCHAR(150) NOT NULL,
  jabatan           VARCHAR(50)  NOT NULL,
  wilayah_tugas     VARCHAR(50)  NOT NULL,
  persen_komisi     DECIMAL(6,4) NOT NULL,
  berlaku_mulai     DATE         NOT NULL,
  berlaku_sampai    DATE         NOT NULL,
  is_current        BOOLEAN      NOT NULL,
  PRIMARY KEY (sales_person_key),
  CONSTRAINT uq_sales_person_versi UNIQUE (sales_person_id, berlaku_mulai),
  CONSTRAINT ck_sales_person_periode CHECK (berlaku_mulai <= berlaku_sampai)
) ENGINE=InnoDB;

-- SCD tipe 1. Wilayah penjualan (10 wilayah). Dimensi conformed dengan proses lain di kelas.
CREATE TABLE dim_wilayah (
  wilayah_key     INT          NOT NULL AUTO_INCREMENT,
  wilayah_id      INT          NOT NULL,      -- TerritoryID
  nama_wilayah    VARCHAR(50)  NOT NULL,      -- mis. Southeast, Canada
  kode_negara     VARCHAR(3)   NOT NULL,      -- US, CA, FR, DE, AU, GB
  nama_negara     VARCHAR(50)  NOT NULL,      -- mis. United States
  grup_wilayah    VARCHAR(50)  NOT NULL,      -- North America, Europe, Pacific
  PRIMARY KEY (wilayah_key),
  CONSTRAINT uq_wilayah_id UNIQUE (wilayah_id)
) ENGINE=InnoDB;

-- SCD tipe 1. Mata uang transaksi (semua kode di sales.currency). Nilai uang di fakta tetap dalam USD.
CREATE TABLE dim_mata_uang (
  mata_uang_key   INT          NOT NULL AUTO_INCREMENT,
  kode_mata_uang  CHAR(3)      NOT NULL,      -- kode ISO, mis. USD
  nama_mata_uang  VARCHAR(100) NOT NULL,      -- mis. US Dollar
  PRIMARY KEY (mata_uang_key),
  CONSTRAINT uq_mata_uang_kode UNIQUE (kode_mata_uang)
) ENGINE=InnoDB;

-- SCD tipe 1. Metode kirim (5 metode di sumber; pesanan reseller hanya memakai CARGO TRANSPORT 5).
CREATE TABLE dim_metode_kirim (
  metode_key      INT           NOT NULL AUTO_INCREMENT,
  metode_id       INT           NOT NULL,     -- ShipMethodID
  nama_metode     VARCHAR(50)   NOT NULL,
  tarif_dasar     DECIMAL(12,4) NOT NULL,     -- ShipBase
  tarif_per_kg    DECIMAL(12,4) NOT NULL,     -- ShipRate
  PRIMARY KEY (metode_key),
  CONSTRAINT uq_metode_id UNIQUE (metode_id)
) ENGINE=InnoDB;

-- SCD tipe 1. Satu baris per program promosi; "No Discount" juga satu baris.
CREATE TABLE dim_promosi (
  promosi_key       INT          NOT NULL AUTO_INCREMENT,
  promosi_id        INT          NOT NULL,
  nama_promosi      VARCHAR(255) NOT NULL,
  jenis_promosi     VARCHAR(50)  NOT NULL,
  kategori_promosi  VARCHAR(50)  NOT NULL,
  persen_diskon     DECIMAL(6,4) NOT NULL,
  tanggal_mulai     DATE         NOT NULL,
  tanggal_selesai   DATE         NOT NULL,
  qty_min           INT          NOT NULL,
  qty_maks          INT          NOT NULL,    -- -1 = tanpa batas atas (di sumber NULL)
  PRIMARY KEY (promosi_key),
  CONSTRAINT uq_promosi_id UNIQUE (promosi_id)
) ENGINE=InnoDB;

-- 3. Baris "Tidak diketahui" (key -1) di setiap dimensi ------------------------
INSERT INTO dim_produk
  (produk_key, produk_id, nama_produk, nomor_produk, warna, subkategori, kategori, biaya_standar, harga_jual,
   berlaku_mulai, berlaku_sampai, is_current)
VALUES
  (-1, -1, 'Tidak diketahui', '-', 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 0, 0,
   '1900-01-01', '9999-12-31', TRUE);

INSERT INTO dim_reseller
  (reseller_key, reseller_id, nama_reseller, tipe_bisnis, spesialisasi, tahun_buka, jumlah_karyawan, kota, provinsi, negara)
VALUES
  (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', -1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui');

INSERT INTO dim_wilayah
  (wilayah_key, wilayah_id, nama_wilayah, kode_negara, nama_negara, grup_wilayah)
VALUES
  (-1, -1, 'Tidak diketahui', '-', 'Tidak diketahui', 'Tidak diketahui');

INSERT INTO dim_mata_uang
  (mata_uang_key, kode_mata_uang, nama_mata_uang)
VALUES
  (-1, '---', 'Tidak diketahui');

INSERT INTO dim_metode_kirim
  (metode_key, metode_id, nama_metode, tarif_dasar, tarif_per_kg)
VALUES
  (-1, -1, 'Tidak diketahui', 0, 0);

INSERT INTO dim_sales_person
  (sales_person_key, sales_person_id, nama_sales_person, jabatan, wilayah_tugas, persen_komisi, berlaku_mulai, berlaku_sampai, is_current)
VALUES
  (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 0, '1900-01-01', '9999-12-31', TRUE);

INSERT INTO dim_promosi
  (promosi_key, promosi_id, nama_promosi, jenis_promosi, kategori_promosi, persen_diskon, tanggal_mulai, tanggal_selesai, qty_min, qty_maks)
VALUES
  (-1, -1, 'Tidak diketahui', 'Tidak diketahui', 'Tidak diketahui', 0, '1900-01-01', '9999-12-31', 0, -1);

-- 4. Fakta ------------------------------------------------------------------
-- Grain: satu baris per baris pesanan reseller (satu produk dalam satu pesanan).
CREATE TABLE fact_penjualan_reseller (
  nomor_pesanan           VARCHAR(25)   NOT NULL,   -- degenerate: SalesOrderNumber
  nomor_baris_pesanan     INT           NOT NULL,   -- degenerate: SalesOrderDetailID
  nomor_po_reseller       VARCHAR(25)   NULL,       -- degenerate: PurchaseOrderNumber
  tanggal_pesan_key       INT           NOT NULL,
  tanggal_jatuh_tempo_key INT           NOT NULL,
  tanggal_kirim_key       INT           NOT NULL,
  produk_key              INT           NOT NULL,
  reseller_key            INT           NOT NULL,
  sales_person_key        INT           NOT NULL,
  promosi_key             INT           NOT NULL,
  wilayah_key             INT           NOT NULL,
  mata_uang_key           INT           NOT NULL,   -- USD, CAD, GBP, EUR, AUD (kurs kosong di sumber = USD)
  metode_key              INT           NOT NULL,
  jumlah_unit             INT           NOT NULL,
  nilai_penjualan         DECIMAL(14,4) NOT NULL,
  nilai_diskon            DECIMAL(14,4) NOT NULL DEFAULT 0,
  total_biaya_produk      DECIMAL(14,4) NOT NULL,
  harga_satuan            DECIMAL(14,4) NOT NULL,
  PRIMARY KEY (nomor_pesanan, nomor_baris_pesanan),
  -- Index pada setiap foreign key (ditulis eksplisit supaya terlihat di ERD dan daftar periksa)
  KEY ix_fpr_tanggal_pesan      (tanggal_pesan_key),
  KEY ix_fpr_tanggal_jatuh_tempo (tanggal_jatuh_tempo_key),
  KEY ix_fpr_tanggal_kirim      (tanggal_kirim_key),
  KEY ix_fpr_produk             (produk_key),
  KEY ix_fpr_reseller           (reseller_key),
  KEY ix_fpr_sales_person       (sales_person_key),
  KEY ix_fpr_promosi            (promosi_key),
  KEY ix_fpr_wilayah            (wilayah_key),
  KEY ix_fpr_mata_uang          (mata_uang_key),
  KEY ix_fpr_metode             (metode_key),
  CONSTRAINT fk_fpr_tanggal_pesan       FOREIGN KEY (tanggal_pesan_key)       REFERENCES dim_tanggal (tanggal_key),
  CONSTRAINT fk_fpr_tanggal_jatuh_tempo FOREIGN KEY (tanggal_jatuh_tempo_key) REFERENCES dim_tanggal (tanggal_key),
  CONSTRAINT fk_fpr_tanggal_kirim       FOREIGN KEY (tanggal_kirim_key)       REFERENCES dim_tanggal (tanggal_key),
  CONSTRAINT fk_fpr_produk              FOREIGN KEY (produk_key)              REFERENCES dim_produk (produk_key),
  CONSTRAINT fk_fpr_reseller            FOREIGN KEY (reseller_key)            REFERENCES dim_reseller (reseller_key),
  CONSTRAINT fk_fpr_sales_person        FOREIGN KEY (sales_person_key)        REFERENCES dim_sales_person (sales_person_key),
  CONSTRAINT fk_fpr_promosi             FOREIGN KEY (promosi_key)             REFERENCES dim_promosi (promosi_key),
  CONSTRAINT fk_fpr_wilayah             FOREIGN KEY (wilayah_key)             REFERENCES dim_wilayah (wilayah_key),
  CONSTRAINT fk_fpr_mata_uang           FOREIGN KEY (mata_uang_key)           REFERENCES dim_mata_uang (mata_uang_key),
  CONSTRAINT fk_fpr_metode              FOREIGN KEY (metode_key)              REFERENCES dim_metode_kirim (metode_key),
  CONSTRAINT ck_fpr_jumlah_unit CHECK (jumlah_unit > 0),
  CONSTRAINT ck_fpr_nilai_penjualan CHECK (nilai_penjualan >= 0),
  CONSTRAINT ck_fpr_nilai_diskon CHECK (nilai_diskon >= 0)
) ENGINE=InnoDB;
