-- uji-constraint.sql | MySQL/MariaDB | Kelompok X
-- Jalankan di database DW SETELAH ddl.sql. Jalankan SATU PERINTAH DALAM SATU WAKTU
-- (di phpMyAdmin: blok satu INSERT, klik Kirim), lalu simpan tangkapan layar pesan errornya.
-- Hasil yang diharapkan ada di komentar masing-masing uji.
-- Urutan kolom fakta: nomor_pesanan, nomor_baris_pesanan, nomor_po_reseller,
--   tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key, produk_key, reseller_key,
--   sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
--   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan
-- Memakai kolom bernama supaya tidak bergantung pada urutan.

-- ====== Tiga uji wajib dari dosen ======

-- Uji 1: FOREIGN KEY. Produk dengan key 99999 tidak ada.
-- Harus GAGAL: Error 1452 ... a foreign key constraint fails (fk_fpr_produk)
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-1', 1, 20130315, 20130327, 20130322, 99999, -1, -1, -1, -1, -1, -1, 1, 10, 0, 5, 10);

-- Uji 2: CHECK. Jumlah unit nol tidak masuk akal.
-- Harus GAGAL: Error 4025 / 3819 ... Constraint 'ck_fpr_jumlah_unit' failed
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-2', 1, 20130315, 20130327, 20130322, -1, -1, -1, -1, -1, -1, -1, 0, 10, 0, 5, 10);

-- Uji 3: PRIMARY KEY. Jalankan perintah ini DUA KALI.
-- Pertama: BERHASIL (1 baris). Kedua: harus GAGAL: Error 1062 Duplicate entry 'UJI-3-1' for key 'PRIMARY'
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-3', 1, 20130315, 20130327, 20130322, -1, -1, -1, -1, -1, -1, -1, 1, 10, 0, 5, 10);

-- ====== Uji tambahan tim (mengecek constraint yang khusus di desain kami) ======

-- Uji 4: FOREIGN KEY ke dim_tanggal. Tanggal 20200101 ada di luar 2010-2015.
-- Harus GAGAL: Error 1452 ... (fk_fpr_tanggal_pesan)
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-4', 1, 20200101, 20130327, 20130322, -1, -1, -1, -1, -1, -1, -1, 1, 10, 0, 5, 10);

-- Uji 5: NOT NULL. Key tidak boleh kosong (pakai -1, bukan NULL).
-- Harus GAGAL: Error 1048 Column 'produk_key' cannot be null
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-5', 1, 20130315, 20130327, 20130322, NULL, -1, -1, -1, -1, -1, -1, 1, 10, 0, 5, 10);

-- Uji 6: UNIQUE (produk_id, berlaku_mulai) pada dim_produk. Versi produk -1 yang mulai 1900-01-01 sudah ada.
-- Harus GAGAL: Error 1062 Duplicate entry '-1-1900-01-01' for key 'uq_produk_versi'
INSERT INTO dim_produk
  (produk_id, nama_produk, nomor_produk, warna, subkategori, kategori, biaya_standar, harga_jual, berlaku_mulai, berlaku_sampai, is_current)
VALUES (-1, 'X', 'X', 'X', 'X', 'X', 1, 1, '1900-01-01', '9999-12-31', TRUE);

-- Uji 7: UNIQUE (sales_person_id, berlaku_mulai) pada dimensi tipe 2. Dua versi yang mulai di hari yang sama.
-- Jalankan dua kali. Pertama BERHASIL, kedua harus GAGAL: Error 1062 ... for key 'uq_sales_person_versi'
INSERT INTO dim_sales_person
  (sales_person_id, nama_sales_person, jabatan, wilayah_tugas, persen_komisi, berlaku_mulai, berlaku_sampai, is_current)
VALUES (-99, 'UJI-7', 'Uji', 'Uji', 0, '2012-01-01', '2012-05-29', FALSE);

-- Uji 8: CHECK periode versi tipe 2 terbalik (mulai setelah sampai).
-- Harus GAGAL: Constraint 'ck_sales_person_periode' failed
INSERT INTO dim_sales_person
  (sales_person_id, nama_sales_person, jabatan, wilayah_tugas, persen_komisi, berlaku_mulai, berlaku_sampai, is_current)
VALUES (-98, 'UJI-8', 'Uji', 'Uji', 0, '2012-06-01', '2012-05-29', FALSE);

-- Uji 9: FOREIGN KEY dari sisi dimensi. Menghapus dim_produk -1 yang dipakai fakta UJI-3 harus ditolak.
-- Harus GAGAL: Error 1451 Cannot delete or update a parent row (fk_fpr_produk)
DELETE FROM dim_produk WHERE produk_key = -1;

-- Uji 10: FOREIGN KEY ke dim_mata_uang. Mata uang dengan key 99999 tidak ada.
-- Harus GAGAL: Error 1452 ... a foreign key constraint fails (fk_fpr_mata_uang)
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-10', 1, 20130315, 20130327, 20130322, -1, -1, -1, -1, -1, 99999, -1, 1, 10, 0, 5, 10);

-- Uji 11: UNIQUE kode_mata_uang pada dim_mata_uang. Kode '---' (baris -1) sudah ada.
-- Harus GAGAL: Error 1062 Duplicate entry '---' for key 'uq_mata_uang_kode'
INSERT INTO dim_mata_uang (kode_mata_uang, nama_mata_uang) VALUES ('---', 'UJI-11');

-- Uji 12: FOREIGN KEY ke dim_wilayah dan dim_metode_kirim. Kedua key 99999 tidak ada.
-- Harus GAGAL: Error 1452 ... (fk_fpr_wilayah atau fk_fpr_metode, mana yang diperiksa lebih dulu)
INSERT INTO fact_penjualan_reseller
  (nomor_pesanan, nomor_baris_pesanan, tanggal_pesan_key, tanggal_jatuh_tempo_key, tanggal_kirim_key,
   produk_key, reseller_key, sales_person_key, promosi_key, wilayah_key, mata_uang_key, metode_key,
   jumlah_unit, nilai_penjualan, nilai_diskon, total_biaya_produk, harga_satuan)
VALUES ('UJI-12', 1, 20130315, 20130327, 20130322, -1, -1, -1, -1, 99999, -1, 99999, 1, 10, 0, 5, 10);

-- ====== Bersihkan setelah selesai ======
DELETE FROM fact_penjualan_reseller WHERE nomor_pesanan LIKE 'UJI-%';
DELETE FROM dim_sales_person WHERE sales_person_id IN (-99, -98);
-- Cek akhir: harus 0 baris fakta dan 1 baris (key -1) di dim_sales_person dan dim_produk
SELECT (SELECT COUNT(*) FROM fact_penjualan_reseller) AS baris_fakta,
       (SELECT COUNT(*) FROM dim_sales_person)        AS baris_dim_sales_person,
       (SELECT COUNT(*) FROM dim_produk)              AS baris_dim_produk;
