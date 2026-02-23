-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES - FINAL WORKING VERSION
-- UMSIDA CONNECT - Supabase Security
-- ============================================================================
-- CARA PAKAI:
-- 1. Buka Supabase SQL Editor
-- 2. JANGAN pilih role apapun (biarkan default)
-- 3. Copy-paste SEMUA query ini
-- 4. Click "Run" atau tekan F5
-- 5. Tunggu sampai selesai (30-60 detik)
-- ============================================================================

-- ============================================================================
-- STEP 1: ENABLE RLS untuk semua table
-- ============================================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE mahasiswa_aktif ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE umkm ENABLE ROW LEVEL SECURITY;
ALTER TABLE produk ENABLE ROW LEVEL SECURITY;
ALTER TABLE pesanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE detail_pesanan ENABLE ROW LEVEL SECURITY;
ALTER TABLE pengiriman ENABLE ROW LEVEL SECURITY;
ALTER TABLE riwayat ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifikasi ENABLE ROW LEVEL SECURITY;
ALTER TABLE penarikan_saldo ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE kampus_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE titik_antar ENABLE ROW LEVEL SECURITY;
ALTER TABLE rating_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaksi_keuangan ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: DROP existing policies if any
-- ============================================================================

DROP POLICY IF EXISTS "users_select_own" ON users;
DROP POLICY IF EXISTS "users_update_own" ON users;
DROP POLICY IF EXISTS "users_select_admin" ON users;
DROP POLICY IF EXISTS "users_update_admin" ON users;
DROP POLICY IF EXISTS "users_insert_public" ON users;
DROP POLICY IF EXISTS "users_delete_admin" ON users;

DROP POLICY IF EXISTS "mahasiswa_select_public" ON mahasiswa_aktif;
DROP POLICY IF EXISTS "mahasiswa_all_admin" ON mahasiswa_aktif;

DROP POLICY IF EXISTS "drivers_select_own" ON drivers;
DROP POLICY IF EXISTS "drivers_update_own" ON drivers;
DROP POLICY IF EXISTS "drivers_select_online" ON drivers;
DROP POLICY IF EXISTS "drivers_insert_own" ON drivers;
DROP POLICY IF EXISTS "drivers_select_admin" ON drivers;
DROP POLICY IF EXISTS "drivers_update_admin" ON drivers;

DROP POLICY IF EXISTS "umkm_select_own" ON umkm;
DROP POLICY IF EXISTS "umkm_update_own" ON umkm;
DROP POLICY IF EXISTS "umkm_select_open" ON umkm;
DROP POLICY IF EXISTS "umkm_insert_own" ON umkm;
DROP POLICY IF EXISTS "umkm_select_admin" ON umkm;
DROP POLICY IF EXISTS "umkm_update_admin" ON umkm;

DROP POLICY IF EXISTS "produk_all_owner" ON produk;
DROP POLICY IF EXISTS "produk_select_available" ON produk;
DROP POLICY IF EXISTS "produk_select_admin" ON produk;
DROP POLICY IF EXISTS "produk_delete_admin" ON produk;

DROP POLICY IF EXISTS "pesanan_select_customer" ON pesanan;
DROP POLICY IF EXISTS "pesanan_insert_customer" ON pesanan;
DROP POLICY IF EXISTS "pesanan_update_customer" ON pesanan;
DROP POLICY IF EXISTS "pesanan_select_driver" ON pesanan;
DROP POLICY IF EXISTS "pesanan_update_driver" ON pesanan;
DROP POLICY IF EXISTS "pesanan_select_umkm" ON pesanan;
DROP POLICY IF EXISTS "pesanan_update_umkm" ON pesanan;
DROP POLICY IF EXISTS "pesanan_select_admin" ON pesanan;
DROP POLICY IF EXISTS "pesanan_update_admin" ON pesanan;

DROP POLICY IF EXISTS "detail_select_customer" ON detail_pesanan;
DROP POLICY IF EXISTS "detail_insert_customer" ON detail_pesanan;
DROP POLICY IF EXISTS "detail_select_umkm" ON detail_pesanan;
DROP POLICY IF EXISTS "detail_select_driver" ON detail_pesanan;
DROP POLICY IF EXISTS "detail_select_admin" ON detail_pesanan;

DROP POLICY IF EXISTS "pengiriman_select_driver" ON pengiriman;
DROP POLICY IF EXISTS "pengiriman_update_driver" ON pengiriman;
DROP POLICY IF EXISTS "pengiriman_insert_driver" ON pengiriman;
DROP POLICY IF EXISTS "pengiriman_select_customer" ON pengiriman;
DROP POLICY IF EXISTS "pengiriman_select_umkm" ON pengiriman;
DROP POLICY IF EXISTS "pengiriman_select_admin" ON pengiriman;

DROP POLICY IF EXISTS "notifikasi_select_own" ON notifikasi;
DROP POLICY IF EXISTS "notifikasi_update_own" ON notifikasi;
DROP POLICY IF EXISTS "notifikasi_insert_system" ON notifikasi;
DROP POLICY IF EXISTS "notifikasi_delete_own" ON notifikasi;

DROP POLICY IF EXISTS "withdrawal_select_own" ON penarikan_saldo;
DROP POLICY IF EXISTS "withdrawal_insert_own" ON penarikan_saldo;
DROP POLICY IF EXISTS "withdrawal_select_admin" ON penarikan_saldo;
DROP POLICY IF EXISTS "withdrawal_update_admin" ON penarikan_saldo;

DROP POLICY IF EXISTS "rating_insert_own" ON rating_reviews;
DROP POLICY IF EXISTS "rating_select_own" ON rating_reviews;
DROP POLICY IF EXISTS "rating_select_public" ON rating_reviews;
DROP POLICY IF EXISTS "rating_all_admin" ON rating_reviews;

DROP POLICY IF EXISTS "transaksi_select_own" ON transaksi_keuangan;
DROP POLICY IF EXISTS "transaksi_insert_system" ON transaksi_keuangan;
DROP POLICY IF EXISTS "transaksi_select_admin" ON transaksi_keuangan;

DROP POLICY IF EXISTS "adminlogs_all_admin" ON admin_logs;

DROP POLICY IF EXISTS "kampus_select_public" ON kampus_locations;
DROP POLICY IF EXISTS "kampus_all_admin" ON kampus_locations;

DROP POLICY IF EXISTS "titik_select_active" ON titik_antar;
DROP POLICY IF EXISTS "titik_all_admin" ON titik_antar;

DROP POLICY IF EXISTS "riwayat_select_own" ON riwayat;
DROP POLICY IF EXISTS "riwayat_insert_system" ON riwayat;
DROP POLICY IF EXISTS "riwayat_select_admin" ON riwayat;

-- ============================================================================
-- STEP 3: CREATE POLICIES - TABLE: users
-- ============================================================================

-- Users dapat melihat profile sendiri
CREATE POLICY "users_select_own" ON users
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

-- Users dapat update profile sendiri
CREATE POLICY "users_update_own" ON users
    FOR UPDATE
    USING (id_user = (SELECT auth.uid()))
    WITH CHECK (id_user = (SELECT auth.uid()));

-- Admin dapat melihat semua users
CREATE POLICY "users_select_admin" ON users
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Admin dapat update semua users
CREATE POLICY "users_update_admin" ON users
    FOR UPDATE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Public dapat register
CREATE POLICY "users_insert_public" ON users
    FOR INSERT
    WITH CHECK (true);

-- Admin dapat delete users
CREATE POLICY "users_delete_admin" ON users
    FOR DELETE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 4: CREATE POLICIES - TABLE: mahasiswa_aktif
-- ============================================================================

-- Public dapat check NIM untuk verifikasi
CREATE POLICY "mahasiswa_select_public" ON mahasiswa_aktif
    FOR SELECT
    USING (true);

-- Admin dapat manage semua
CREATE POLICY "mahasiswa_all_admin" ON mahasiswa_aktif
    FOR ALL
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin')
    WITH CHECK ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 5: CREATE POLICIES - TABLE: drivers
-- ============================================================================

-- Driver dapat melihat data sendiri
CREATE POLICY "drivers_select_own" ON drivers
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

-- Driver dapat update data sendiri
CREATE POLICY "drivers_update_own" ON drivers
    FOR UPDATE
    USING (id_user = (SELECT auth.uid()));

-- Users dapat melihat driver yang online
CREATE POLICY "drivers_select_online" ON drivers
    FOR SELECT
    USING (status_driver = 'online');

-- New drivers dapat insert
CREATE POLICY "drivers_insert_own" ON drivers
    FOR INSERT
    WITH CHECK (id_user = (SELECT auth.uid()));

-- Admin dapat melihat semua
CREATE POLICY "drivers_select_admin" ON drivers
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Admin dapat update
CREATE POLICY "drivers_update_admin" ON drivers
    FOR UPDATE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 6: CREATE POLICIES - TABLE: umkm
-- ============================================================================

-- UMKM dapat melihat data sendiri
CREATE POLICY "umkm_select_own" ON umkm
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

-- UMKM dapat update data sendiri
CREATE POLICY "umkm_update_own" ON umkm
    FOR UPDATE
    USING (id_user = (SELECT auth.uid()));

-- Public dapat melihat toko yang buka
CREATE POLICY "umkm_select_open" ON umkm
    FOR SELECT
    USING (status_toko = 'buka');

-- New UMKM dapat insert
CREATE POLICY "umkm_insert_own" ON umkm
    FOR INSERT
    WITH CHECK (id_user = (SELECT auth.uid()));

-- Admin dapat melihat semua
CREATE POLICY "umkm_select_admin" ON umkm
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Admin dapat update
CREATE POLICY "umkm_update_admin" ON umkm
    FOR UPDATE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 7: CREATE POLICIES - TABLE: produk
-- ============================================================================

-- UMKM dapat manage produk sendiri
CREATE POLICY "produk_all_owner" ON produk
    FOR ALL
    USING (
        id_umkm IN (
            SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        id_umkm IN (
            SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
        )
    );

-- Public dapat melihat produk available
CREATE POLICY "produk_select_available" ON produk
    FOR SELECT
    USING (
        is_available = true 
        AND id_umkm IN (
            SELECT id_umkm FROM umkm WHERE status_toko = 'buka'
        )
    );

-- Admin dapat melihat semua
CREATE POLICY "produk_select_admin" ON produk
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Admin dapat delete
CREATE POLICY "produk_delete_admin" ON produk
    FOR DELETE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 8: CREATE POLICIES - TABLE: pesanan
-- ============================================================================

-- Customer dapat melihat pesanan sendiri
CREATE POLICY "pesanan_select_customer" ON pesanan
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

-- Customer dapat create pesanan
CREATE POLICY "pesanan_insert_customer" ON pesanan
    FOR INSERT
    WITH CHECK (id_user = (SELECT auth.uid()));

-- Customer dapat update pesanan sendiri
CREATE POLICY "pesanan_update_customer" ON pesanan
    FOR UPDATE
    USING (
        id_user = (SELECT auth.uid()) 
        AND status_pesanan IN ('menunggu_driver', 'menunggu_konfirmasi_penjual')
    );

-- Driver dapat melihat pesanan yang di-assign
CREATE POLICY "pesanan_select_driver" ON pesanan
    FOR SELECT
    USING (
        id_pesanan IN (
            SELECT id_pesanan FROM pengiriman 
            WHERE id_driver IN (
                SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
            )
        )
    );

-- Driver dapat update pesanan yang di-assign
CREATE POLICY "pesanan_update_driver" ON pesanan
    FOR UPDATE
    USING (
        id_pesanan IN (
            SELECT id_pesanan FROM pengiriman 
            WHERE id_driver IN (
                SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
            )
        )
    );

-- UMKM dapat melihat pesanan produk mereka
CREATE POLICY "pesanan_select_umkm" ON pesanan
    FOR SELECT
    USING (
        jenis = 'umkm' 
        AND id_pesanan IN (
            SELECT id_pesanan FROM detail_pesanan 
            WHERE id_produk IN (
                SELECT id_produk FROM produk 
                WHERE id_umkm IN (
                    SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
                )
            )
        )
    );

-- UMKM dapat update pesanan mereka
CREATE POLICY "pesanan_update_umkm" ON pesanan
    FOR UPDATE
    USING (
        jenis = 'umkm' 
        AND id_pesanan IN (
            SELECT id_pesanan FROM detail_pesanan 
            WHERE id_produk IN (
                SELECT id_produk FROM produk 
                WHERE id_umkm IN (
                    SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
                )
            )
        )
    );

-- Admin dapat melihat semua
CREATE POLICY "pesanan_select_admin" ON pesanan
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- Admin dapat update semua
CREATE POLICY "pesanan_update_admin" ON pesanan
    FOR UPDATE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 9: CREATE POLICIES - TABLE: detail_pesanan
-- ============================================================================

CREATE POLICY "detail_select_customer" ON detail_pesanan
    FOR SELECT
    USING (
        id_pesanan IN (
            SELECT id_pesanan FROM pesanan WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "detail_insert_customer" ON detail_pesanan
    FOR INSERT
    WITH CHECK (
        id_pesanan IN (
            SELECT id_pesanan FROM pesanan WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "detail_select_umkm" ON detail_pesanan
    FOR SELECT
    USING (
        id_produk IN (
            SELECT id_produk FROM produk 
            WHERE id_umkm IN (
                SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
            )
        )
    );

CREATE POLICY "detail_select_driver" ON detail_pesanan
    FOR SELECT
    USING (
        id_pesanan IN (
            SELECT id_pesanan FROM pengiriman 
            WHERE id_driver IN (
                SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
            )
        )
    );

CREATE POLICY "detail_select_admin" ON detail_pesanan
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 10: CREATE POLICIES - TABLE: pengiriman
-- ============================================================================

CREATE POLICY "pengiriman_select_driver" ON pengiriman
    FOR SELECT
    USING (
        id_driver IN (
            SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "pengiriman_update_driver" ON pengiriman
    FOR UPDATE
    USING (
        id_driver IN (
            SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "pengiriman_insert_driver" ON pengiriman
    FOR INSERT
    WITH CHECK (
        id_driver IN (
            SELECT id_driver FROM drivers WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "pengiriman_select_customer" ON pengiriman
    FOR SELECT
    USING (
        id_pesanan IN (
            SELECT id_pesanan FROM pesanan WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "pengiriman_select_umkm" ON pengiriman
    FOR SELECT
    USING (
        id_pesanan IN (
            SELECT p.id_pesanan FROM pesanan p
            JOIN detail_pesanan dp ON p.id_pesanan = dp.id_pesanan
            JOIN produk pr ON dp.id_produk = pr.id_produk
            WHERE pr.id_umkm IN (
                SELECT id_umkm FROM umkm WHERE id_user = (SELECT auth.uid())
            )
        )
    );

CREATE POLICY "pengiriman_select_admin" ON pengiriman
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 11: CREATE POLICIES - TABLE: notifikasi
-- ============================================================================

CREATE POLICY "notifikasi_select_own" ON notifikasi
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "notifikasi_update_own" ON notifikasi
    FOR UPDATE
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "notifikasi_insert_system" ON notifikasi
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "notifikasi_delete_own" ON notifikasi
    FOR DELETE
    USING (id_user = (SELECT auth.uid()));

-- ============================================================================
-- STEP 12: CREATE POLICIES - TABLE: penarikan_saldo
-- ============================================================================

CREATE POLICY "withdrawal_select_own" ON penarikan_saldo
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "withdrawal_insert_own" ON penarikan_saldo
    FOR INSERT
    WITH CHECK (id_user = (SELECT auth.uid()));

CREATE POLICY "withdrawal_select_admin" ON penarikan_saldo
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

CREATE POLICY "withdrawal_update_admin" ON penarikan_saldo
    FOR UPDATE
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 13: CREATE POLICIES - TABLE: rating_reviews
-- ============================================================================

CREATE POLICY "rating_insert_own" ON rating_reviews
    FOR INSERT
    WITH CHECK (
        id_user = (SELECT auth.uid())
        AND id_pesanan IN (
            SELECT id_pesanan FROM pesanan WHERE id_user = (SELECT auth.uid())
        )
    );

CREATE POLICY "rating_select_own" ON rating_reviews
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "rating_select_public" ON rating_reviews
    FOR SELECT
    USING (true);

CREATE POLICY "rating_all_admin" ON rating_reviews
    FOR ALL
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin')
    WITH CHECK ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 14: CREATE POLICIES - TABLE: transaksi_keuangan
-- ============================================================================

CREATE POLICY "transaksi_select_own" ON transaksi_keuangan
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "transaksi_insert_system" ON transaksi_keuangan
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "transaksi_select_admin" ON transaksi_keuangan
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 15: CREATE POLICIES - TABLE: admin_logs
-- ============================================================================

CREATE POLICY "adminlogs_all_admin" ON admin_logs
    FOR ALL
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin')
    WITH CHECK ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 16: CREATE POLICIES - TABLE: kampus_locations & titik_antar
-- ============================================================================

CREATE POLICY "kampus_select_public" ON kampus_locations
    FOR SELECT
    USING (true);

CREATE POLICY "kampus_all_admin" ON kampus_locations
    FOR ALL
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin')
    WITH CHECK ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

CREATE POLICY "titik_select_active" ON titik_antar
    FOR SELECT
    USING (is_active = true);

CREATE POLICY "titik_all_admin" ON titik_antar
    FOR ALL
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin')
    WITH CHECK ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- STEP 17: CREATE POLICIES - TABLE: riwayat
-- ============================================================================

CREATE POLICY "riwayat_select_own" ON riwayat
    FOR SELECT
    USING (id_user = (SELECT auth.uid()));

CREATE POLICY "riwayat_insert_system" ON riwayat
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "riwayat_select_admin" ON riwayat
    FOR SELECT
    USING ((SELECT role FROM users WHERE id_user = (SELECT auth.uid())) = 'admin');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check RLS enabled
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Enabled'
        ELSE '❌ RLS Disabled'
    END as status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check policies count
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- SUCCESS! RLS POLICIES APPLIED
-- ============================================================================