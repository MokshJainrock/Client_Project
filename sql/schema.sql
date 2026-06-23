-- ============================================================
-- Client Data Management & Analytics System
-- schema.sql  —  database structure (4 normalized tables)
-- ============================================================
-- Run this first to create the database and tables before
-- loading data with etl.py.

CREATE DATABASE IF NOT EXISTS client_analytics;
USE client_analytics;

-- One row per customer. total_spend, order_count and segment
-- are filled in from the transaction data / analysis.
CREATE TABLE clients (
    customer_id   VARCHAR(20) PRIMARY KEY,
    country       VARCHAR(100),
    first_seen    DATE,
    last_seen     DATE,
    total_spend   DECIMAL(12,2),
    order_count   INT,
    segment       VARCHAR(50)
);

-- One row per product. Stored once instead of repeating product
-- details on every transaction line.
CREATE TABLE products (
    stock_code    VARCHAR(20) PRIMARY KEY,
    description   VARCHAR(255),
    price         DECIMAL(10,2)
);

-- One row per invoice (order). Links to the client.
CREATE TABLE transactions (
    invoice       VARCHAR(20) PRIMARY KEY,
    customer_id   VARCHAR(20),
    invoice_date  DATETIME,
    total_amount  DECIMAL(12,2),
    FOREIGN KEY (customer_id) REFERENCES clients(customer_id)
);

-- One row per product within an order. unit_price is stored here
-- because the price at time of sale can differ from the current
-- product price.
CREATE TABLE transaction_items (
    item_id       INT AUTO_INCREMENT PRIMARY KEY,
    invoice       VARCHAR(20),
    stock_code    VARCHAR(20),
    quantity      INT,
    unit_price    DECIMAL(10,2),
    FOREIGN KEY (invoice) REFERENCES transactions(invoice),
    FOREIGN KEY (stock_code) REFERENCES products(stock_code)
);
