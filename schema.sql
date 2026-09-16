CREATE TABLE IF NOT EXISTS users (
 id BIGSERIAL PRIMARY KEY,
 public_id VARCHAR(40) UNIQUE NOT NULL,
 full_name VARCHAR(150) NOT NULL,
 email VARCHAR(320) UNIQUE,
 phone VARCHAR(40) UNIQUE,
 password_hash TEXT NOT NULL,
 role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin','superadmin','operations','support')),
 kyc_status VARCHAR(20) NOT NULL DEFAULT 'unverified' CHECK (kyc_status IN ('unverified','pending','verified','rejected')),
 whatsapp VARCHAR(40), telegram VARCHAR(80), live_notifications BOOLEAN NOT NULL DEFAULT TRUE,
 points NUMERIC(30,10) NOT NULL DEFAULT 0,
 active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS wallets (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 wallet_type VARCHAR(20) NOT NULL CHECK (wallet_type IN ('safe','smart')),
 currency VARCHAR(12) NOT NULL, balance NUMERIC(30,10) NOT NULL DEFAULT 0,
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE(user_id,wallet_type,currency)
);
CREATE TABLE IF NOT EXISTS transactions (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 type VARCHAR(30) NOT NULL CHECK(type IN ('deposit','withdrawal','exchange','internal_transfer')),
 wallet_type VARCHAR(20), currency VARCHAR(12) NOT NULL, amount NUMERIC(30,10) NOT NULL,
 fee NUMERIC(30,10) NOT NULL DEFAULT 0, net_amount NUMERIC(30,10), reference VARCHAR(120) UNIQUE,
 payment_method VARCHAR(80), destination TEXT, target_currency VARCHAR(12), target_amount NUMERIC(30,10),
 status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected','completed','held')),
 metadata JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS ledger (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 wallet_id BIGINT REFERENCES wallets(id) ON DELETE SET NULL, transaction_id BIGINT REFERENCES transactions(id) ON DELETE SET NULL,
 currency VARCHAR(12) NOT NULL, movement_type VARCHAR(40) NOT NULL, amount NUMERIC(30,10) NOT NULL,
 fee NUMERIC(30,10) NOT NULL DEFAULT 0, balance_before NUMERIC(30,10) NOT NULL, balance_after NUMERIC(30,10) NOT NULL,
 actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL, note TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS kyc_submissions (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 full_name VARCHAR(150), document_type VARCHAR(50), document_ref TEXT, status VARCHAR(20) NOT NULL DEFAULT 'pending',
 reviewed_by BIGINT REFERENCES users(id), reviewed_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS audit_logs (
 id BIGSERIAL PRIMARY KEY, actor_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
 action VARCHAR(100) NOT NULL, target_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
 details JSONB NOT NULL DEFAULT '{}'::jsonb, ip_address INET, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS referrals (
 id BIGSERIAL PRIMARY KEY, referrer_user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
 referred_user_id BIGINT UNIQUE REFERENCES users(id) ON DELETE CASCADE, code VARCHAR(40) UNIQUE NOT NULL,
 points_awarded NUMERIC(30,10) NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS wheel_spins (
 id BIGSERIAL PRIMARY KEY, user_id BIGINT REFERENCES users(id) ON DELETE CASCADE, prize VARCHAR(120) NOT NULL,
 points_awarded NUMERIC(30,10) NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS settings (key VARCHAR(80) PRIMARY KEY, value JSONB NOT NULL);
INSERT INTO settings(key,value) VALUES
('fees','{"deposit":0,"withdrawal":5,"exchange":5,"internal_swap":5}'),
('smart_bonus','{"percent":3}'),
('supported_currencies','["USD","SYP","EUR","USDT"]'),
('referral_reward','{"points":50}'),
('wheel_enabled','true') ON CONFLICT(key) DO NOTHING;
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON transactions(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_user_created ON ledger(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target_created ON audit_logs(target_user_id,created_at DESC);
