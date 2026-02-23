-- ============================================================================
-- DATABASE SCHEMA: UMSIDA CONNECT
-- Aplikasi Layanan Ojek & UMKM Kampus
-- ============================================================================
-- Created: 2025
-- Database: PostgreSQL 15+
-- Purpose: Schema lengkap untuk sistem ojek dan UMKM kampus UMSIDA
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable PostGIS for location features (optional, tapi recommended untuk GPS)
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================================
-- CUSTOM TYPES (ENUMS)
-- ============================================================================

-- Status User
CREATE TYPE user_status AS ENUM (
    'active',
    'suspended',
    'inactive',
    'pending_verification'
);

-- Role User
CREATE TYPE user_role AS ENUM (
    'customer',
    'driver',
    'umkm',
    'admin'
);

-- Status Driver
CREATE TYPE driver_status AS ENUM (
    'online',
    'offline',
    'busy'
);

-- Status Toko UMKM
CREATE TYPE toko_status AS ENUM (
    'buka',
    'tutup',
    'suspended'
);

-- Kategori Produk
CREATE TYPE kategori_produk AS ENUM (
    'makanan',
    'minuman',
    'snack',
    'kue',
    'lauk',
    'lainnya'
);

-- Jenis Pesanan
CREATE TYPE jenis_pesanan AS ENUM (
    'ojek',
    'umkm'
);

-- Status Pesanan Ojek
CREATE TYPE status_pesanan_ojek AS ENUM (
    'menunggu_driver',
    'driver_diterima',
    'driver_menuju_pickup',
    'customer_dijemput',
    'perjalanan',
    'selesai',
    'dibatalkan'
);

-- Status Pesanan UMKM
CREATE TYPE status_pesanan_umkm AS ENUM (
    'menunggu_konfirmasi_penjual',
    'dikonfirmasi_penjual',
    'diproses',
    'siap_diambil',
    'menunggu_driver',
    'driver_mengambil',
    'dalam_pengantaran',
    'selesai',
    'dibatalkan'
);

-- Jenis Notifikasi
CREATE TYPE jenis_notifikasi AS ENUM (
    'pesanan',
    'pembayaran',
    'sistem',
    'promo',
    'withdrawal'
);

-- Status Notifikasi
CREATE TYPE status_notifikasi AS ENUM (
    'unread',
    'read'
);

-- Status Penarikan Saldo
CREATE TYPE status_penarikan AS ENUM (
    'pending',
    'diproses',
    'selesai',
    'ditolak'
);

-- Jenis Bank
CREATE TYPE jenis_bank AS ENUM (
    'BCA',
    'BRI',
    'BNI',
    'Mandiri',
    'BSI',
    'CIMB',
    'Permata',
    'Danamon',
    'BTPN',
    'Lainnya'
);

-- ============================================================================
-- TABLE: users
-- Master table untuk semua user (customer, driver, umkm, admin)
-- ============================================================================
CREATE TABLE users (
    id_user UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nim VARCHAR(20) UNIQUE NOT NULL,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    no_telp VARCHAR(20) NOT NULL,
    password_hash TEXT NOT NULL,
    foto_profil TEXT,
    role user_role NOT NULL DEFAULT 'customer',
    status user_status NOT NULL DEFAULT 'pending_verification',
    is_verified BOOLEAN DEFAULT FALSE,
    alamat TEXT,
    tanggal_lahir DATE,
    jenis_kelamin VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    
    -- Indexes
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_nim_check CHECK (LENGTH(nim) >= 8)
);

-- Indexes untuk performa
CREATE INDEX idx_users_nim ON users(nim);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);

-- ============================================================================
-- TABLE: mahasiswa_aktif
-- Database mahasiswa aktif UMSIDA untuk verifikasi
-- ============================================================================
CREATE TABLE mahasiswa_aktif (
    id_mahasiswa UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nim VARCHAR(20) UNIQUE NOT NULL,
    nama_lengkap VARCHAR(100) NOT NULL,
    program_studi VARCHAR(100),
    fakultas VARCHAR(100),
    angkatan VARCHAR(10),
    status_mahasiswa VARCHAR(20) DEFAULT 'aktif',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT mahasiswa_aktif_nim_check CHECK (LENGTH(nim) >= 8)
);

CREATE INDEX idx_mahasiswa_aktif_nim ON mahasiswa_aktif(nim);

-- ============================================================================
-- TABLE: drivers
-- Data khusus untuk driver
-- ============================================================================
CREATE TABLE drivers (
    id_driver UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    status_driver driver_status DEFAULT 'offline',
    rating_driver DECIMAL(3,2) DEFAULT 0.00 CHECK (rating_driver >= 0 AND rating_driver <= 5),
    total_rating INT DEFAULT 0,
    jumlah_pesanan_selesai INT DEFAULT 0,
    saldo_tersedia DECIMAL(12,2) DEFAULT 0.00 CHECK (saldo_tersedia >= 0),
    total_pendapatan DECIMAL(12,2) DEFAULT 0.00,
    
    -- Data Kendaraan
    jenis_kendaraan VARCHAR(50),
    plat_nomor VARCHAR(20),
    merk_kendaraan VARCHAR(50),
    warna_kendaraan VARCHAR(30),
    
    -- Data Bank untuk withdrawal
    nama_bank jenis_bank,
    nama_rekening VARCHAR(100),
    nomor_rekening VARCHAR(30),
    
    -- GPS Location (menggunakan PostGIS)
    current_location GEOGRAPHY(POINT, 4326),
    last_location_update TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT drivers_user_unique UNIQUE(id_user)
);

CREATE INDEX idx_drivers_user ON drivers(id_user);
CREATE INDEX idx_drivers_status ON drivers(status_driver);
CREATE INDEX idx_drivers_location ON drivers USING GIST(current_location);

-- ============================================================================
-- TABLE: umkm
-- Data toko UMKM mahasiswa
-- ============================================================================
CREATE TABLE umkm (
    id_umkm UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    nama_toko VARCHAR(100) NOT NULL,
    alamat_toko TEXT NOT NULL,
    deskripsi_toko TEXT,
    foto_toko TEXT,
    rating_toko DECIMAL(3,2) DEFAULT 0.00 CHECK (rating_toko >= 0 AND rating_toko <= 5),
    total_rating INT DEFAULT 0,
    status_toko toko_status DEFAULT 'tutup',
    
    -- Finansial
    saldo_tersedia DECIMAL(12,2) DEFAULT 0.00 CHECK (saldo_tersedia >= 0),
    total_penjualan DECIMAL(12,2) DEFAULT 0.00,
    jumlah_produk_terjual INT DEFAULT 0,
    
    -- Data Bank
    nama_bank jenis_bank,
    nama_rekening VARCHAR(100),
    nomor_rekening VARCHAR(30),
    
    -- Lokasi Toko
    lokasi_toko GEOGRAPHY(POINT, 4326),
    
    jam_buka TIME,
    jam_tutup TIME,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT umkm_user_unique UNIQUE(id_user)
);

CREATE INDEX idx_umkm_user ON umkm(id_user);
CREATE INDEX idx_umkm_status ON umkm(status_toko);
CREATE INDEX idx_umkm_nama ON umkm(nama_toko);
CREATE INDEX idx_umkm_rating ON umkm(rating_toko DESC);

-- ============================================================================
-- TABLE: produk
-- Produk yang dijual oleh UMKM
-- ============================================================================
CREATE TABLE produk (
    id_produk UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_umkm UUID NOT NULL REFERENCES umkm(id_umkm) ON DELETE CASCADE,
    nama_produk VARCHAR(100) NOT NULL,
    deskripsi_produk TEXT,
    harga_produk DECIMAL(12,2) NOT NULL CHECK (harga_produk > 0),
    kategori kategori_produk NOT NULL,
    stok INT DEFAULT 0 CHECK (stok >= 0),
    is_available BOOLEAN DEFAULT TRUE,
    
    -- Foto produk (array of URLs)
    foto_produk TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Rating & Review
    rating_produk DECIMAL(3,2) DEFAULT 0.00 CHECK (rating_produk >= 0 AND rating_produk <= 5),
    total_rating INT DEFAULT 0,
    total_terjual INT DEFAULT 0,
    
    -- Estimasi
    waktu_persiapan_menit INT DEFAULT 15,
    berat_gram INT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_produk_umkm ON produk(id_umkm);
CREATE INDEX idx_produk_kategori ON produk(kategori);
CREATE INDEX idx_produk_available ON produk(is_available);
CREATE INDEX idx_produk_rating ON produk(rating_produk DESC);
CREATE INDEX idx_produk_nama ON produk(nama_produk);

-- ============================================================================
-- TABLE: pesanan
-- Master table untuk semua pesanan (ojek & umkm)
-- ============================================================================
CREATE TABLE pesanan (
    id_pesanan UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user),
    jenis jenis_pesanan NOT NULL,
    
    -- Lokasi
    alamat_asal TEXT,
    alamat_tujuan TEXT NOT NULL,
    lokasi_asal GEOGRAPHY(POINT, 4326),
    lokasi_tujuan GEOGRAPHY(POINT, 4326),
    jarak_km DECIMAL(5,2),
    
    -- Pilihan Kampus
    kampus_asal VARCHAR(20), -- 'Kampus 1', 'Kampus 2', 'Kampus 3'
    kampus_tujuan VARCHAR(20),
    
    -- Finansial
    total_harga DECIMAL(12,2) NOT NULL CHECK (total_harga >= 0),
    ongkir DECIMAL(12,2) DEFAULT 0.00,
    subtotal DECIMAL(12,2) DEFAULT 0.00,
    fee_admin DECIMAL(12,2) DEFAULT 0.00,
    fee_payment_gateway DECIMAL(12,2) DEFAULT 0.00,
    
    -- Status & Timestamps
    status_pesanan TEXT NOT NULL, -- Will store either ojek or umkm status
    tanggal_pesanan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Catatan
    catatan TEXT,
    
    -- Payment
    payment_method VARCHAR(50),
    payment_status VARCHAR(20) DEFAULT 'pending',
    payment_id TEXT, -- ID dari Midtrans
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pesanan_user ON pesanan(id_user);
CREATE INDEX idx_pesanan_jenis ON pesanan(jenis);
CREATE INDEX idx_pesanan_status ON pesanan(status_pesanan);
CREATE INDEX idx_pesanan_tanggal ON pesanan(tanggal_pesanan DESC);
CREATE INDEX idx_pesanan_payment_status ON pesanan(payment_status);

-- ============================================================================
-- TABLE: detail_pesanan
-- Detail produk dalam pesanan UMKM
-- ============================================================================
CREATE TABLE detail_pesanan (
    id_detail UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_pesanan UUID NOT NULL REFERENCES pesanan(id_pesanan) ON DELETE CASCADE,
    id_produk UUID NOT NULL REFERENCES produk(id_produk),
    jumlah INT NOT NULL CHECK (jumlah > 0),
    harga_satuan DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    catatan_item TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_detail_pesanan ON detail_pesanan(id_pesanan);
CREATE INDEX idx_detail_produk ON detail_pesanan(id_produk);

-- ============================================================================
-- TABLE: pengiriman
-- Data pengiriman untuk driver
-- ============================================================================
CREATE TABLE pengiriman (
    id_pengiriman UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_pesanan UUID NOT NULL REFERENCES pesanan(id_pesanan) ON DELETE CASCADE,
    id_driver UUID REFERENCES drivers(id_driver),
    
    -- Status & Time Tracking
    status_pengiriman VARCHAR(50) NOT NULL,
    waktu_terima TIMESTAMP,
    waktu_pickup TIMESTAMP,
    waktu_antar TIMESTAMP,
    waktu_selesai TIMESTAMP,
    
    -- Estimasi
    estimasi_waktu_menit INT,
    
    -- Rating dari customer ke driver
    rating_pengiriman INT CHECK (rating_pengiriman >= 1 AND rating_pengiriman <= 5),
    komentar_pengiriman TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT pengiriman_pesanan_unique UNIQUE(id_pesanan)
);

CREATE INDEX idx_pengiriman_pesanan ON pengiriman(id_pesanan);
CREATE INDEX idx_pengiriman_driver ON pengiriman(id_driver);
CREATE INDEX idx_pengiriman_status ON pengiriman(status_pengiriman);

-- ============================================================================
-- TABLE: riwayat
-- Riwayat transaksi lengkap (untuk laporan)
-- ============================================================================
CREATE TABLE riwayat (
    id_riwayat UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user),
    id_pesanan UUID NOT NULL REFERENCES pesanan(id_pesanan),
    jenis_transaksi VARCHAR(20) NOT NULL,
    total_transaksi DECIMAL(12,2) NOT NULL,
    tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    komentar TEXT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_riwayat_user ON riwayat(id_user);
CREATE INDEX idx_riwayat_pesanan ON riwayat(id_pesanan);
CREATE INDEX idx_riwayat_tanggal ON riwayat(tanggal DESC);

-- ============================================================================
-- TABLE: notifikasi
-- Sistem notifikasi untuk semua user
-- ============================================================================
CREATE TABLE notifikasi (
    id_notifikasi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user) ON DELETE CASCADE,
    judul VARCHAR(200) NOT NULL,
    pesan TEXT NOT NULL,
    jenis jenis_notifikasi NOT NULL,
    status status_notifikasi DEFAULT 'unread',
    
    -- Data tambahan dalam format JSON
    data_tambahan JSONB,
    
    -- Link/Action
    action_url TEXT,
    
    tanggal_notifikasi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tanggal_dibaca TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifikasi_user ON notifikasi(id_user);
CREATE INDEX idx_notifikasi_status ON notifikasi(status);
CREATE INDEX idx_notifikasi_tanggal ON notifikasi(tanggal_notifikasi DESC);
CREATE INDEX idx_notifikasi_jenis ON notifikasi(jenis);

-- ============================================================================
-- TABLE: penarikan_saldo (Withdrawal)
-- Request penarikan saldo driver & UMKM
-- ============================================================================
CREATE TABLE penarikan_saldo (
    id_penarikan UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_user UUID NOT NULL REFERENCES users(id_user),
    jumlah DECIMAL(12,2) NOT NULL CHECK (jumlah > 0),
    
    -- Rekening Tujuan
    nama_bank jenis_bank NOT NULL,
    nama_rekening VARCHAR(100) NOT NULL,
    nomor_rekening VARCHAR(30) NOT NULL,
    
    -- Status & Processing
    status status_penarikan DEFAULT 'pending',
    tanggal_pengajuan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tanggal_diproses TIMESTAMP,
    tanggal_selesai TIMESTAMP,
    
    -- Admin handling
    id_admin UUID REFERENCES users(id_user),
    catatan_admin TEXT,
    bukti_transfer TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_penarikan_user ON penarikan_saldo(id_user);
CREATE INDEX idx_penarikan_status ON penarikan_saldo(status);
CREATE INDEX idx_penarikan_tanggal ON penarikan_saldo(tanggal_pengajuan DESC);

-- ============================================================================
-- TABLE: admin_logs
-- Log aktivitas admin untuk audit trail
-- ============================================================================
CREATE TABLE admin_logs (
    id_log UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_admin UUID NOT NULL REFERENCES users(id_user),
    aksi VARCHAR(100) NOT NULL,
    target_type VARCHAR(50), -- 'user', 'pesanan', 'withdrawal', dll
    target_id UUID,
    detail JSONB,
    ip_address INET,
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_logs_admin ON admin_logs(id_admin);
CREATE INDEX idx_admin_logs_aksi ON admin_logs(aksi);
CREATE INDEX idx_admin_logs_timestamp ON admin_logs(timestamp DESC);
CREATE INDEX idx_admin_logs_target ON admin_logs(target_type, target_id);

-- ============================================================================
-- TABLE: kampus_locations
-- Lokasi koordinat kampus UMSIDA
-- ============================================================================
CREATE TABLE kampus_locations (
    id_kampus UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nama_kampus VARCHAR(50) NOT NULL UNIQUE,
    alamat TEXT NOT NULL,
    koordinat GEOGRAPHY(POINT, 4326) NOT NULL,
    radius_layanan_meter INT DEFAULT 10000, -- 10km
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert koordinat kampus UMSIDA (data approximate dari Google Maps)
INSERT INTO kampus_locations (nama_kampus, alamat, koordinat) VALUES
    ('Kampus 1', 'Jl. Mojopahit 666B, Sidoarjo', ST_SetSRID(ST_MakePoint(112.7177, -7.4478), 4326)),
    ('Kampus 2', 'Jl. Raya Gelam 250, Sidoarjo', ST_SetSRID(ST_MakePoint(112.7194, -7.4489), 4326)),
    ('Kampus 3', 'Jl. Raya Pondok Jati, Sidoarjo', ST_SetSRID(ST_MakePoint(112.7125, -7.4523), 4326));

CREATE INDEX idx_kampus_koordinat ON kampus_locations USING GIST(koordinat);

-- ============================================================================
-- TABLE: titik_antar
-- Titik-titik strategis dalam kampus untuk antar jemput
-- ============================================================================
CREATE TABLE titik_antar (
    id_titik UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_kampus UUID REFERENCES kampus_locations(id_kampus),
    nama_titik VARCHAR(100) NOT NULL,
    deskripsi TEXT,
    gedung VARCHAR(50),
    lantai INT,
    koordinat GEOGRAPHY(POINT, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_titik_kampus ON titik_antar(id_kampus);
CREATE INDEX idx_titik_koordinat ON titik_antar USING GIST(koordinat);

-- ============================================================================
-- TABLE: rating_reviews
-- Rating dan review untuk driver & produk
-- ============================================================================
CREATE TABLE rating_reviews (
    id_review UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_pesanan UUID NOT NULL REFERENCES pesanan(id_pesanan),
    id_user UUID NOT NULL REFERENCES users(id_user),
    
    -- Target rating (driver atau produk)
    target_type VARCHAR(20) NOT NULL, -- 'driver' atau 'produk'
    target_id UUID NOT NULL,
    
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT rating_reviews_pesanan_target_unique UNIQUE(id_pesanan, target_type, target_id)
);

CREATE INDEX idx_rating_user ON rating_reviews(id_user);
CREATE INDEX idx_rating_target ON rating_reviews(target_type, target_id);
CREATE INDEX idx_rating_pesanan ON rating_reviews(id_pesanan);

-- ============================================================================
-- TABLE: transaksi_keuangan
-- Log semua transaksi keuangan untuk transparansi
-- ============================================================================
CREATE TABLE transaksi_keuangan (
    id_transaksi UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_pesanan UUID REFERENCES pesanan(id_pesanan),
    id_user UUID NOT NULL REFERENCES users(id_user),
    
    jenis_transaksi VARCHAR(50) NOT NULL, -- 'payment', 'split_driver', 'split_umkm', 'split_admin', 'withdrawal'
    jumlah DECIMAL(12,2) NOT NULL,
    saldo_sebelum DECIMAL(12,2),
    saldo_sesudah DECIMAL(12,2),
    
    deskripsi TEXT,
    metadata JSONB,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_transaksi_user ON transaksi_keuangan(id_user);
CREATE INDEX idx_transaksi_pesanan ON transaksi_keuangan(id_pesanan);
CREATE INDEX idx_transaksi_jenis ON transaksi_keuangan(jenis_transaksi);
CREATE INDEX idx_transaksi_tanggal ON transaksi_keuangan(created_at DESC);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto update updated_at untuk semua table yang punya kolom ini
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at BEFORE UPDATE ON drivers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_umkm_updated_at BEFORE UPDATE ON umkm
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_produk_updated_at BEFORE UPDATE ON produk
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pesanan_updated_at BEFORE UPDATE ON pesanan
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pengiriman_updated_at BEFORE UPDATE ON pengiriman
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_penarikan_updated_at BEFORE UPDATE ON penarikan_saldo
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Function: Hitung jarak antara 2 koordinat (dalam km)
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    point1 GEOGRAPHY;
    point2 GEOGRAPHY;
    distance_meters DOUBLE PRECISION;
BEGIN
    point1 := ST_SetSRID(ST_MakePoint(lon1, lat1), 4326)::GEOGRAPHY;
    point2 := ST_SetSRID(ST_MakePoint(lon2, lat2), 4326)::GEOGRAPHY;
    distance_meters := ST_Distance(point1, point2);
    RETURN distance_meters / 1000.0; -- Convert to KM
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- Function: Cek apakah lokasi dalam radius kampus
-- ============================================================================
CREATE OR REPLACE FUNCTION is_within_campus_radius(
    user_lat DOUBLE PRECISION,
    user_lon DOUBLE PRECISION,
    max_radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS BOOLEAN AS $$
DECLARE
    user_location GEOGRAPHY;
    kampus_record RECORD;
    distance_km DOUBLE PRECISION;
BEGIN
    user_location := ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::GEOGRAPHY;
    
    -- Cek ke semua kampus
    FOR kampus_record IN SELECT * FROM kampus_locations LOOP
        distance_km := ST_Distance(user_location, kampus_record.koordinat) / 1000.0;
        
        IF distance_km <= max_radius_km THEN
            RETURN TRUE;
        END IF;
    END LOOP;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Function: Update rating driver setelah ada rating baru
-- ============================================================================
CREATE OR REPLACE FUNCTION update_driver_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_reviews INT;
BEGIN
    -- Hitung rata-rata rating untuk driver ini
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_rating, total_reviews
    FROM rating_reviews
    WHERE target_type = 'driver' AND target_id = NEW.target_id;
    
    -- Update driver table
    UPDATE drivers
    SET 
        rating_driver = avg_rating,
        total_rating = total_reviews
    WHERE id_driver = NEW.target_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_driver_rating
AFTER INSERT ON rating_reviews
FOR EACH ROW
WHEN (NEW.target_type = 'driver')
EXECUTE FUNCTION update_driver_rating();

-- ============================================================================
-- Function: Update rating produk setelah ada rating baru
-- ============================================================================
CREATE OR REPLACE FUNCTION update_produk_rating()
RETURNS TRIGGER AS $$
DECLARE
    avg_rating DECIMAL(3,2);
    total_reviews INT;
BEGIN
    SELECT 
        COALESCE(AVG(rating), 0),
        COUNT(*)
    INTO avg_rating, total_reviews
    FROM rating_reviews
    WHERE target_type = 'produk' AND target_id = NEW.target_id;
    
    UPDATE produk
    SET 
        rating_produk = avg_rating,
        total_rating = total_reviews
    WHERE id_produk = NEW.target_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_produk_rating
AFTER INSERT ON rating_reviews
FOR EACH ROW
WHEN (NEW.target_type = 'produk')
EXECUTE FUNCTION update_produk_rating();

-- ============================================================================
-- Function: Log transaksi keuangan otomatis
-- ============================================================================
CREATE OR REPLACE FUNCTION log_transaksi_keuangan()
RETURNS TRIGGER AS $$
BEGIN
    -- Log saat saldo berubah
    IF OLD.saldo_tersedia IS DISTINCT FROM NEW.saldo_tersedia THEN
        INSERT INTO transaksi_keuangan (
            id_user,
            jenis_transaksi,
            jumlah,
            saldo_sebelum,
            saldo_sesudah,
            deskripsi
        ) VALUES (
            NEW.id_user,
            'saldo_update',
            NEW.saldo_tersedia - OLD.saldo_tersedia,
            OLD.saldo_tersedia,
            NEW.saldo_tersedia,
            'Perubahan saldo'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk drivers
CREATE TRIGGER trigger_log_driver_saldo
AFTER UPDATE ON drivers
FOR EACH ROW
EXECUTE FUNCTION log_transaksi_keuangan();

-- Trigger untuk umkm
CREATE TRIGGER trigger_log_umkm_saldo
AFTER UPDATE ON umkm
FOR EACH ROW
EXECUTE FUNCTION log_transaksi_keuangan();

-- ============================================================================
-- VIEWS untuk kemudahan query
-- ============================================================================

-- View: Dashboard Admin
CREATE OR REPLACE VIEW view_admin_dashboard AS
SELECT 
    (SELECT COUNT(*) FROM users WHERE status = 'active') as total_users_active,
    (SELECT COUNT(*) FROM drivers WHERE status_driver = 'online') as total_drivers_online,
    (SELECT COUNT(*) FROM umkm WHERE status_toko = 'buka') as total_umkm_open,
    (SELECT COUNT(*) FROM pesanan WHERE DATE(created_at) = CURRENT_DATE) as total_pesanan_today,
    (SELECT COALESCE(SUM(total_harga), 0) FROM pesanan WHERE DATE(created_at) = CURRENT_DATE) as total_revenue_today,
    (SELECT COALESCE(SUM(fee_admin), 0) FROM pesanan WHERE payment_status = 'success') as total_admin_fee;

-- View: Pesanan dengan detail lengkap
CREATE OR REPLACE VIEW view_pesanan_lengkap AS
SELECT 
    p.*,
    u.nama as nama_customer,
    u.no_telp as telp_customer,
    d.id_driver,
    du.nama as nama_driver,
    du.no_telp as telp_driver,
    pg.status_pengiriman,
    pg.waktu_terima,
    pg.waktu_selesai
FROM pesanan p
LEFT JOIN users u ON p.id_user = u.id_user
LEFT JOIN pengiriman pg ON p.id_pesanan = pg.id_pesanan
LEFT JOIN drivers d ON pg.id_driver = d.id_driver
LEFT JOIN users du ON d.id_user = du.id_user;

-- View: Produk dengan info UMKM
CREATE OR REPLACE VIEW view_produk_umkm AS
SELECT 
    p.*,
    u.nama_toko,
    u.rating_toko,
    u.status_toko,
    us.nama as nama_pemilik,
    us.no_telp as telp_pemilik
FROM produk p
JOIN umkm u ON p.id_umkm = u.id_umkm
JOIN users us ON u.id_user = us.id_user;

-- ============================================================================
-- SEED DATA untuk testing
-- ============================================================================

-- Insert admin default
INSERT INTO users (nim, nama, email, no_telp, password_hash, role, status, is_verified)
VALUES ('000000000001', 'Admin UMSIDA Connect', 'admin@umsida.ac.id', '081234567890', 
        '$2a$10$example_hash_password', 'admin', 'active', TRUE);

-- Insert contoh mahasiswa aktif untuk testing
INSERT INTO mahasiswa_aktif (nim, nama_lengkap, program_studi, fakultas, angkatan, status_mahasiswa)
VALUES 
    ('221080200036', 'Muhammad Sulthon Abiyyu', 'Informatika', 'Sains dan Teknologi', '2022', 'aktif'),
    ('221080200001', 'Ahmad Fauzi', 'Informatika', 'Sains dan Teknologi', '2022', 'aktif'),
    ('221080200002', 'Siti Nurhaliza', 'Sistem Informasi', 'Sains dan Teknologi', '2022', 'aktif'),
    ('221080200003', 'Budi Santoso', 'Teknik Elektro', 'Teknik', '2022', 'aktif'),
    ('221080200004', 'Dewi Lestari', 'Manajemen', 'Ekonomi', '2022', 'aktif');

-- ============================================================================
-- COMMENTS untuk dokumentasi
-- ============================================================================
COMMENT ON TABLE users IS 'Master table untuk semua pengguna aplikasi';
COMMENT ON TABLE mahasiswa_aktif IS 'Database mahasiswa aktif UMSIDA untuk verifikasi NIM';
COMMENT ON TABLE drivers IS 'Data khusus driver ojek kampus';
COMMENT ON TABLE umkm IS 'Data toko UMKM mahasiswa';
COMMENT ON TABLE produk IS 'Produk yang dijual oleh UMKM';
COMMENT ON TABLE pesanan IS 'Master table semua pesanan (ojek & UMKM)';
COMMENT ON TABLE pengiriman IS 'Data pengiriman dan tracking';
COMMENT ON TABLE notifikasi IS 'Sistem notifikasi push untuk semua user';
COMMENT ON TABLE penarikan_saldo IS 'Request penarikan saldo driver & UMKM';
COMMENT ON TABLE admin_logs IS 'Audit trail aktivitas admin';
COMMENT ON TABLE kampus_locations IS 'Koordinat lokasi kampus UMSIDA';
COMMENT ON TABLE rating_reviews IS 'Rating dan review untuk driver & produk';

-- ============================================================================
-- GRANTS (akan disesuaikan dengan Supabase RLS)
-- ============================================================================
-- Note: Supabase akan handle ini dengan Row Level Security (RLS)
-- Yang akan kita setup di step berikutnya

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
