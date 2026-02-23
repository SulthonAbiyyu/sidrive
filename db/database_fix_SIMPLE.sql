-- ============================================================================
-- DATABASE FIX SIMPLE - UMSIDA CONNECT
-- Versi Simple - Hanya Yang Penting!
-- ============================================================================
-- Cara pakai: Copy SEMUA, Paste di SQL Editor, Run!
-- ============================================================================

-- 1. ADMIN TIDAK PERLU NIM
ALTER TABLE users ALTER COLUMN nim DROP NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_nim_required CHECK ((role = 'admin') OR (nim IS NOT NULL));

-- 2. TABLE TARIF OJEK
CREATE TABLE IF NOT EXISTS tarif_settings (
    id_tarif UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jenis_kendaraan VARCHAR(20) NOT NULL UNIQUE,
    base_fare DECIMAL(10,2) NOT NULL,
    rate_per_km DECIMAL(10,2) NOT NULL,
    max_jarak_km DECIMAL(5,2) DEFAULT 10.00,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert tarif default
INSERT INTO tarif_settings (jenis_kendaraan, base_fare, rate_per_km, max_jarak_km)
VALUES 
    ('motor', 5000.00, 2000.00, 10.00),
    ('mobil', 10000.00, 4000.00, 10.00)
ON CONFLICT (jenis_kendaraan) DO NOTHING;

-- 3. TABLE KOMISI PLATFORM
CREATE TABLE IF NOT EXISTS komisi_settings (
    id_komisi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jenis VARCHAR(20) NOT NULL UNIQUE,
    persentase DECIMAL(5,2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert komisi default
INSERT INTO komisi_settings (jenis, persentase)
VALUES 
    ('driver', 20.00),
    ('umkm', 10.00)
ON CONFLICT (jenis) DO NOTHING;

-- 4. FUNCTION HITUNG HARGA
CREATE OR REPLACE FUNCTION calculate_harga_ojek(
    p_jenis_kendaraan VARCHAR,
    p_jarak_km DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    v_base_fare DECIMAL;
    v_rate_per_km DECIMAL;
BEGIN
    SELECT base_fare, rate_per_km
    INTO v_base_fare, v_rate_per_km
    FROM tarif_settings
    WHERE jenis_kendaraan = p_jenis_kendaraan;
    
    RETURN v_base_fare + (p_jarak_km * v_rate_per_km);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST / VERIFICATION
-- ============================================================================

-- Check tarif
SELECT * FROM tarif_settings;

-- Check komisi
SELECT * FROM komisi_settings;

-- Test hitung harga motor 5km (Expected: 15000)
SELECT calculate_harga_ojek('motor', 5.0) as harga_motor_5km;

-- Test hitung harga mobil 5km (Expected: 30000)
SELECT calculate_harga_ojek('mobil', 5.0) as harga_mobil_5km;

-- ============================================================================
-- SELESAI!
-- Kalau muncul hasil di atas tanpa error = SUKSES! ✅
-- ============================================================================
