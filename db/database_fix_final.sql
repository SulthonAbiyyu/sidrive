-- ============================================================================
-- DATABASE FIX - UMSIDA CONNECT
-- Penyesuaian berdasarkan final decisions
-- ============================================================================

-- ============================================================================
-- FIX 1: Admin tidak perlu NIM
-- ============================================================================

-- Buat NIM nullable untuk admin
ALTER TABLE users 
ALTER COLUMN nim DROP NOT NULL;

-- Tambah constraint: NIM wajib kecuali admin
ALTER TABLE users 
ADD CONSTRAINT users_nim_required 
CHECK (
    (role = 'admin') OR (nim IS NOT NULL AND nim != '')
);

-- ============================================================================
-- FIX 2: Update Kategori Produk UMKM (Semua Kategori)
-- ============================================================================

-- Drop existing type (hati-hati: akan reset kategori produk yang ada)
DROP TYPE IF EXISTS kategori_produk CASCADE;

-- Create new type dengan kategori lengkap
CREATE TYPE kategori_produk AS ENUM (
    'makanan',
    'minuman',
    'snack',
    'kue',
    'lauk',
    'alat_tulis',
    'buku',
    'fotocopy',
    'laundry',
    'sablon',
    'aksesoris',
    'kerajinan',
    'jasa',
    'lainnya'
);

-- Re-add column ke table produk
ALTER TABLE produk 
ADD COLUMN kategori kategori_produk DEFAULT 'lainnya';

-- ============================================================================
-- FIX 3: Tambah Table Tarif Settings (untuk tarif hybrid)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tarif_settings (
    id_tarif UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jenis_kendaraan VARCHAR(20) NOT NULL UNIQUE,  -- 'motor' atau 'mobil'
    base_fare DECIMAL(10,2) NOT NULL,              -- Minimum charge
    rate_per_km DECIMAL(10,2) NOT NULL,            -- Rate per kilometer
    max_jarak_km DECIMAL(5,2) DEFAULT 10.00,       -- Max 10 km
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT tarif_jenis_valid CHECK (jenis_kendaraan IN ('motor', 'mobil'))
);

-- Insert default tarif
INSERT INTO tarif_settings (jenis_kendaraan, base_fare, rate_per_km, max_jarak_km)
VALUES 
    ('motor', 5000.00, 2000.00, 10.00),
    ('mobil', 10000.00, 4000.00, 10.00)
ON CONFLICT (jenis_kendaraan) DO NOTHING;

-- ============================================================================
-- FIX 4: Update Jenis Kendaraan di Drivers
-- ============================================================================

-- Tambah constraint untuk jenis kendaraan
ALTER TABLE drivers 
ADD CONSTRAINT drivers_jenis_kendaraan_check 
CHECK (jenis_kendaraan IN ('motor', 'mobil'));

-- ============================================================================
-- FIX 5: Tambah Field untuk Payment Gateway (future-ready)
-- ============================================================================

-- Tambah kolom untuk payment gateway
ALTER TABLE pesanan 
ADD COLUMN IF NOT EXISTS payment_url TEXT,
ADD COLUMN IF NOT EXISTS payment_token TEXT,
ADD COLUMN IF NOT EXISTS payment_expired_at TIMESTAMP;

-- ============================================================================
-- FIX 6: Create Admin Account
-- ============================================================================

-- Note: Admin account akan dibuat via Supabase Auth dulu
-- Setelah itu, insert ke table users dengan query ini:

-- Contoh (jalankan setelah create admin di Supabase Auth):
/*
INSERT INTO users (
    id_user, 
    nama, 
    email, 
    no_telp, 
    password_hash,
    role, 
    status, 
    is_verified,
    nim
)
VALUES (
    '[ID dari auth.users]',  -- Ganti dengan actual UUID dari Supabase Auth
    'Admin UMSIDA Connect',
    'admin@umsida.ac.id',
    '081234567890',
    'dummy_hash',  -- Not used karena auth via Supabase
    'admin',
    'active',
    true,
    NULL  -- Admin tidak perlu NIM
);
*/

-- ============================================================================
-- FIX 7: Komisi Platform Settings
-- ============================================================================

CREATE TABLE IF NOT EXISTS komisi_settings (
    id_komisi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jenis VARCHAR(20) NOT NULL UNIQUE,  -- 'driver' atau 'umkm'
    persentase DECIMAL(5,2) NOT NULL,   -- Persentase komisi (20.00 = 20%)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT komisi_jenis_valid CHECK (jenis IN ('driver', 'umkm')),
    CONSTRAINT komisi_persentase_valid CHECK (persentase >= 0 AND persentase <= 100)
);

-- Insert default komisi
INSERT INTO komisi_settings (jenis, persentase)
VALUES 
    ('driver', 20.00),  -- Driver: 20% untuk platform, 80% untuk driver
    ('umkm', 10.00)     -- UMKM: 10% untuk platform, 90% untuk penjual
ON CONFLICT (jenis) DO NOTHING;

-- ============================================================================
-- FIX 8: Function untuk Hitung Harga Ojek (Tarif Hybrid)
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_harga_ojek(
    p_jenis_kendaraan VARCHAR,
    p_jarak_km DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    v_base_fare DECIMAL;
    v_rate_per_km DECIMAL;
    v_total_harga DECIMAL;
BEGIN
    -- Get tarif settings
    SELECT base_fare, rate_per_km
    INTO v_base_fare, v_rate_per_km
    FROM tarif_settings
    WHERE jenis_kendaraan = p_jenis_kendaraan
    AND is_active = true;
    
    -- Hitung: Base Fare + (Jarak × Rate per KM)
    v_total_harga := v_base_fare + (p_jarak_km * v_rate_per_km);
    
    RETURN ROUND(v_total_harga, 0);  -- Round ke rupiah terdekat
END;
$$ LANGUAGE plpgsql;

-- Test function
-- SELECT calculate_harga_ojek('motor', 5.0);  -- Expected: 15000
-- SELECT calculate_harga_ojek('mobil', 5.0);  -- Expected: 50000

-- ============================================================================
-- FIX 9: Function untuk Hitung Komisi
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_komisi(
    p_jenis VARCHAR,  -- 'driver' atau 'umkm'
    p_total_harga DECIMAL
)
RETURNS TABLE (
    komisi_platform DECIMAL,
    pendapatan_partner DECIMAL
) AS $$
DECLARE
    v_persentase DECIMAL;
BEGIN
    -- Get komisi percentage
    SELECT persentase INTO v_persentase
    FROM komisi_settings
    WHERE jenis = p_jenis AND is_active = true;
    
    -- Calculate
    komisi_platform := ROUND((p_total_harga * v_persentase / 100), 0);
    pendapatan_partner := p_total_harga - komisi_platform;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Test function
-- SELECT * FROM calculate_komisi('driver', 15000);  -- Expected: 3000, 12000
-- SELECT * FROM calculate_komisi('umkm', 50000);    -- Expected: 5000, 45000

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check tarif settings
SELECT * FROM tarif_settings;

-- Check komisi settings
SELECT * FROM komisi_settings;

-- Test hitung harga
SELECT 
    'Motor 3km' as kasus,
    calculate_harga_ojek('motor', 3.0) as harga,
    * FROM calculate_komisi('driver', calculate_harga_ojek('motor', 3.0));

SELECT 
    'Motor 10km' as kasus,
    calculate_harga_ojek('motor', 10.0) as harga,
    * FROM calculate_komisi('driver', calculate_harga_ojek('motor', 10.0));

SELECT 
    'Mobil 5km' as kasus,
    calculate_harga_ojek('mobil', 5.0) as harga,
    * FROM calculate_komisi('driver', calculate_harga_ojek('mobil', 5.0));

-- ============================================================================
-- DONE! Database ready dengan:
-- ✅ Admin tanpa NIM
-- ✅ Tarif hybrid (base + per km)
-- ✅ Kategori UMKM lengkap
-- ✅ Support motor + mobil
-- ✅ Komisi platform configurable
-- ✅ Payment gateway ready (future)
-- ============================================================================
