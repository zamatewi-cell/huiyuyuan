-- ============================================================
-- 汇玉源 PostgreSQL 数据库初始化脚本
-- 运行方式: psql -U huyy_user -d huiyuanyuan -f init_db.sql
-- ============================================================

-- 启用扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- 用户表
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id            VARCHAR(64) PRIMARY KEY DEFAULT 'u_' || replace(gen_random_uuid()::text, '-', ''),
    phone         VARCHAR(20) UNIQUE,
    username      VARCHAR(64) NOT NULL DEFAULT '用户',
    password_hash VARCHAR(256),
    avatar_url    TEXT,
    user_type     VARCHAR(20) NOT NULL DEFAULT 'customer'
                  CHECK (user_type IN ('customer', 'operator', 'admin')),
    operator_num  INTEGER,
    balance       NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    points        INTEGER NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_phone     ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

-- 预置管理员（密码: admin123，bcrypt hash 仅示例，部署时应重新生成）
INSERT INTO users (id, phone, username, password_hash, user_type, balance, points)
VALUES (
    'admin_001',
    '18937766669',
    '超级管理员',
    '$2b$12$placeholder_change_me_before_prod',
    'admin',
    999999.00,
    99999
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 商品表
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    id              VARCHAR(32) PRIMARY KEY,
    name            VARCHAR(128) NOT NULL,
    description     TEXT,
    price           NUMERIC(12,2) NOT NULL,
    original_price  NUMERIC(12,2),
    category        VARCHAR(32),
    material        VARCHAR(64),
    images          JSONB NOT NULL DEFAULT '[]',
    stock           INTEGER NOT NULL DEFAULT 0,
    rating          NUMERIC(3,2) NOT NULL DEFAULT 5.00,
    sales_count     INTEGER NOT NULL DEFAULT 0,
    is_hot          BOOLEAN NOT NULL DEFAULT FALSE,
    is_new          BOOLEAN NOT NULL DEFAULT FALSE,
    is_welfare      BOOLEAN NOT NULL DEFAULT FALSE,
    origin          VARCHAR(128),
    certificate     VARCHAR(256),
    blockchain_hash VARCHAR(256),
    material_verify VARCHAR(64) DEFAULT '天然A货',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_category  ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_material  ON products(material);
CREATE INDEX IF NOT EXISTS idx_products_is_hot    ON products(is_hot);
CREATE INDEX IF NOT EXISTS idx_products_is_new    ON products(is_new);
CREATE INDEX IF NOT EXISTS idx_products_price     ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING GIN (name gin_trgm_ops);

-- ============================================================
-- 收货地址表
-- ============================================================
CREATE TABLE IF NOT EXISTS addresses (
    id             VARCHAR(64) PRIMARY KEY DEFAULT 'addr_' || replace(gen_random_uuid()::text, '-', ''),
    user_id        VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_name VARCHAR(64) NOT NULL,
    phone_number   VARCHAR(20) NOT NULL,
    province       VARCHAR(32) NOT NULL,
    city           VARCHAR(32) NOT NULL,
    district       VARCHAR(32) NOT NULL,
    detail_address TEXT NOT NULL,
    postal_code    VARCHAR(10),
    tag            VARCHAR(16),
    is_default     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses(user_id);

-- ============================================================
-- 购物车表
-- ============================================================
CREATE TABLE IF NOT EXISTS cart_items (
    id         SERIAL PRIMARY KEY,
    user_id    VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id VARCHAR(32) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    selected   BOOLEAN NOT NULL DEFAULT TRUE,
    added_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, product_id)
);

CREATE INDEX IF NOT EXISTS idx_cart_user_id ON cart_items(user_id);

-- ============================================================
-- 订单表
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
    id             VARCHAR(64) PRIMARY KEY DEFAULT 'ord_' || replace(gen_random_uuid()::text, '-', ''),
    user_id        VARCHAR(64) NOT NULL REFERENCES users(id),
    address_id     VARCHAR(64) REFERENCES addresses(id),
    address_snap   JSONB,                          -- 下单时地址快照
    total_amount   NUMERIC(12,2) NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','paid','shipped','delivered','cancelled','refunding','refunded')),
    payment_method VARCHAR(20),
    payment_no     VARCHAR(128),                   -- 支付平台交易号
    remark         TEXT,
    paid_at        TIMESTAMPTZ,
    shipped_at     TIMESTAMPTZ,
    tracking_no    VARCHAR(64),
    completed_at   TIMESTAMPTZ,
    cancelled_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id    ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status     ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- ============================================================
-- 订单明细表
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
    id            SERIAL PRIMARY KEY,
    order_id      VARCHAR(64) NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id    VARCHAR(32) NOT NULL,
    product_snap  JSONB NOT NULL,                  -- 下单时商品快照
    quantity      INTEGER NOT NULL DEFAULT 1,
    unit_price    NUMERIC(12,2) NOT NULL,
    subtotal      NUMERIC(12,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);

-- ============================================================
-- 支付记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS payments (
    id             SERIAL PRIMARY KEY,
    order_id       VARCHAR(64) NOT NULL REFERENCES orders(id),
    user_id        VARCHAR(64) NOT NULL REFERENCES users(id),
    amount         NUMERIC(12,2) NOT NULL,
    method         VARCHAR(20) NOT NULL,           -- wechat / alipay / balance
    trade_no       VARCHAR(128),                   -- 第三方单号
    status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','success','failed','refunded')),
    paid_at        TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_user_id  ON payments(user_id);

-- ============================================================
-- SMS 发送日志（防刷 + 审计）
-- ============================================================
CREATE TABLE IF NOT EXISTS sms_logs (
    id          SERIAL PRIMARY KEY,
    phone       VARCHAR(20) NOT NULL,
    action      VARCHAR(32) NOT NULL DEFAULT 'login',  -- login / register / reset
    biz_id      VARCHAR(128),                          -- 阿里云回执 BizId
    send_status VARCHAR(20) NOT NULL DEFAULT 'sent',   -- sent / failed / verified
    ip_addr     VARCHAR(64),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sms_logs_phone      ON sms_logs(phone);
CREATE INDEX IF NOT EXISTS idx_sms_logs_created_at ON sms_logs(created_at DESC);

-- ============================================================
-- 商品评价表
-- ============================================================
CREATE TABLE IF NOT EXISTS reviews (
    id           VARCHAR(64) PRIMARY KEY DEFAULT 'rev_' || replace(gen_random_uuid()::text, '-', ''),
    product_id   VARCHAR(32) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    order_id     VARCHAR(64) REFERENCES orders(id),
    user_id      VARCHAR(64) NOT NULL REFERENCES users(id),
    rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content      TEXT,
    images       JSONB NOT NULL DEFAULT '[]',
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified  BOOLEAN NOT NULL DEFAULT TRUE,
    like_count   INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id    ON reviews(user_id);

-- ============================================================
-- updated_at 自动更新触发器
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['users','products','orders'] LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger
            WHERE tgname = 'trg_' || tbl || '_updated_at'
        ) THEN
            EXECUTE format(
                'CREATE TRIGGER trg_%s_updated_at
                 BEFORE UPDATE ON %s
                 FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
                tbl, tbl
            );
        END IF;
    END LOOP;
END;
$$;

-- ============================================================
-- 完成
-- ============================================================
DO $$ BEGIN RAISE NOTICE 'init_db.sql executed successfully'; END $$;
