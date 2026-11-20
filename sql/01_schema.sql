-- 01_schema.sql
-- Core Relational Schema for Work-Order & Accounting Workflow

DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS time_entries CASCADE;
DROP TABLE IF EXISTS work_orders CASCADE;
DROP TABLE IF EXISTS service_types CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

-- 1. Clients Table
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(25),
    account_status VARCHAR(20) DEFAULT 'Active' CHECK (account_status IN ('Active', 'Inactive', 'On Hold')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Staff / Preparers Table
CREATE TABLE staff (
    staff_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('Intake Specialist', 'Accountant', 'Inspector', 'Reviewer', 'Partner')),
    hourly_rate NUMERIC(10, 2) NOT NULL CHECK (hourly_rate >= 0),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. Service Catalog (Tax Prep, Audit, Field Inspection, etc.)
CREATE TABLE service_types (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) UNIQUE NOT NULL,
    department VARCHAR(50) NOT NULL,
    base_fee NUMERIC(10, 2) DEFAULT 0.00
);

-- 4. Work Orders (Core Workflow Table)
CREATE TABLE work_orders (
    work_order_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(client_id) ON DELETE RESTRICT,
    assigned_staff_id INT REFERENCES staff(staff_id) ON DELETE SET NULL,
    service_id INT NOT NULL REFERENCES service_types(service_id),
    status VARCHAR(30) NOT NULL DEFAULT 'Intake' 
        CHECK (status IN ('Intake', 'In Progress', 'Pending Client Info', 'Quality Review', 'Completed', 'Billed')),
    priority VARCHAR(15) NOT NULL DEFAULT 'Normal' 
        CHECK (priority IN ('Low', 'Normal', 'High', 'Urgent')),
    due_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Time & Billing Entries
CREATE TABLE time_entries (
    entry_id SERIAL PRIMARY KEY,
    work_order_id INT NOT NULL REFERENCES work_orders(work_order_id) ON DELETE CASCADE,
    staff_id INT NOT NULL REFERENCES staff(staff_id),
    hours_worked NUMERIC(5, 2) NOT NULL CHECK (hours_worked > 0),
    is_billable BOOLEAN DEFAULT TRUE,
    work_notes TEXT,
    logged_date DATE DEFAULT CURRENT_DATE
);

-- 6. Automated Status Audit Trail
CREATE TABLE audit_logs (
    log_id SERIAL PRIMARY KEY,
    work_order_id INT NOT NULL REFERENCES work_orders(work_order_id) ON DELETE CASCADE,
    old_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Performance Indexes for Common Office Lookups
CREATE INDEX idx_work_orders_status ON work_orders(status);
CREATE INDEX idx_work_orders_due_date ON work_orders(due_date);
CREATE INDEX idx_work_orders_client ON work_orders(client_id);
