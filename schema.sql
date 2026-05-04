-- ============================================================
-- SQL Sales Analytics Dashboard — Schema
-- Author: Harshitha S
-- ============================================================

CREATE DATABASE IF NOT EXISTS sales_analytics;
USE sales_analytics;

-- ─── REGIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS regions (
    region_id   INT PRIMARY KEY AUTO_INCREMENT,
    region_name VARCHAR(50) NOT NULL,
    country     VARCHAR(50) NOT NULL
);

-- ─── CUSTOMERS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
    customer_id   INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    segment       ENUM('Consumer', 'Corporate', 'Home Office') NOT NULL,
    join_date     DATE NOT NULL
);

-- ─── PRODUCTS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    product_id   INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100) NOT NULL,
    category     ENUM('Electronics', 'Furniture', 'Office Supplies', 'Clothing', 'Food & Beverages') NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL
);

-- ─── DISCOUNTS ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS discounts (
    discount_id  INT PRIMARY KEY AUTO_INCREMENT,
    product_id   INT NOT NULL,
    discount_pct DECIMAL(5,2) NOT NULL CHECK (discount_pct BETWEEN 0 AND 100),
    valid_from   DATE NOT NULL,
    valid_to     DATE NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ─── ORDERS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    order_id    INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    product_id  INT NOT NULL,
    region_id   INT NOT NULL,
    order_date  DATE NOT NULL,
    quantity    INT NOT NULL CHECK (quantity > 0),
    amount      DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    FOREIGN KEY (region_id)   REFERENCES regions(region_id)
);

-- ─── RETURNS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS returns (
    return_id   INT PRIMARY KEY AUTO_INCREMENT,
    order_id    INT NOT NULL UNIQUE,
    return_date DATE NOT NULL,
    reason      ENUM('Defective', 'Wrong Item', 'Not as Described', 'Changed Mind', 'Damaged in Transit') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- ─── INDEXES FOR QUERY OPTIMISATION ──────────────────────────
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_product    ON orders(product_id);
CREATE INDEX idx_orders_region     ON orders(region_id);
CREATE INDEX idx_discounts_product ON discounts(product_id);
