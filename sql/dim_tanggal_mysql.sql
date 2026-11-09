-- =====================================================================
--  dim_tanggal  standar kelas Data Warehouse  |  versi 1.0  |  MySQL 8.0+
--  Disediakan oleh sponsor. JANGAN mengubah struktur atau isi tabel ini.
--  Butuh atribut lain (misalnya hari libur)? Buat tabel tambahan yang
--  terhubung lewat tanggal_key.
--
--  Cara pakai : jalankan di database DW kelompok (bukan database sumber),
--               SEBELUM membuat tabel fakta.
--  Rentang    : 2010-01-01 s.d. 2015-12-31, ditambah baris -1.
--  Catatan    : butuh MySQL 8.0 atau lebih baru (memakai recursive CTE).
-- =====================================================================

-- Tabel ini gagal dihapus jika sudah dirujuk tabel fakta. Itu disengaja,
-- supaya tidak terhapus tanpa sengaja.
DROP TABLE IF EXISTS dim_tanggal;

CREATE TABLE dim_tanggal (
    tanggal_key          INT          NOT NULL PRIMARY KEY,  -- format YYYYMMDD, -1 = tidak diketahui
    tanggal              DATE         NOT NULL UNIQUE,
    tahun                INT          NOT NULL,
    semester             INT          NOT NULL,     -- 1 = Jan-Jun, 2 = Jul-Des
    kuartal              INT          NOT NULL,     -- 1 s.d. 4
    bulan                INT          NOT NULL,     -- 1 s.d. 12
    nama_bulan           VARCHAR(15)  NOT NULL,     -- Januari ... Desember
    minggu_dalam_tahun   INT          NOT NULL,     -- minggu ISO 8601, 1 s.d. 53
    tanggal_dalam_bulan  INT          NOT NULL,     -- 1 s.d. 31
    hari_dalam_minggu    INT          NOT NULL,     -- Senin = 1 ... Minggu = 7
    nama_hari            VARCHAR(15)  NOT NULL,     -- Senin ... Minggu
    is_akhir_pekan       BOOLEAN      NOT NULL      -- 1 untuk Sabtu dan Minggu
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4
  COMMENT = 'Dimensi tanggal standar kelas DW, versi 1.0';

-- Bawaan MySQL membatasi rekursi 1000 langkah. Rentang ini butuh 2191.
SET SESSION cte_max_recursion_depth = 10000;

-- Satu baris per hari
INSERT INTO dim_tanggal
WITH RECURSIVE hari AS (
    SELECT DATE('2010-01-01') AS d
    UNION ALL
    SELECT d + INTERVAL 1 DAY FROM hari WHERE d < DATE('2015-12-31')
)
SELECT
    CAST(DATE_FORMAT(d, '%Y%m%d') AS UNSIGNED),
    d,
    YEAR(d),
    IF(MONTH(d) <= 6, 1, 2),
    QUARTER(d),
    MONTH(d),
    ELT(MONTH(d), 'Januari','Februari','Maret','April','Mei','Juni','Juli',
                  'Agustus','September','Oktober','November','Desember'),
    WEEK(d, 3),                 -- mode 3 = minggu ISO 8601
    DAY(d),
    WEEKDAY(d) + 1,             -- WEEKDAY: Senin = 0, jadi ditambah 1
    ELT(WEEKDAY(d) + 1, 'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'),
    WEEKDAY(d) >= 5
FROM hari;

-- Baris "Tidak diketahui" untuk fakta yang tanggalnya kosong
INSERT INTO dim_tanggal VALUES
    (-1, '1900-01-01', 0, 0, 0, 0, 'Tidak diketahui', 0, 0, 0, 'Tidak diketahui', FALSE);

-- ---------------------------------------------------------------------
--  Pemeriksaan (hasil yang diharapkan ada di komentar)
-- ---------------------------------------------------------------------
-- 1. Jumlah baris: 2191 hari + 1 baris tidak diketahui = 2192
SELECT COUNT(*) AS jumlah_baris FROM dim_tanggal;

-- 2. Rentang tanggal: 2010-01-01 s.d. 2015-12-31
SELECT MIN(tanggal) AS awal, MAX(tanggal) AS akhir FROM dim_tanggal WHERE tanggal_key > 0;

-- 3. Contoh: 2013-03-15 adalah Jumat, kuartal 1, minggu ISO 11
SELECT * FROM dim_tanggal WHERE tanggal_key = 20130315;

-- 4. Perhatikan: 1 Januari bisa masuk minggu ISO 52/53 tahun sebelumnya
SELECT tanggal, nama_hari, minggu_dalam_tahun FROM dim_tanggal
WHERE tanggal IN ('2010-01-01', '2011-01-01', '2012-01-01');
