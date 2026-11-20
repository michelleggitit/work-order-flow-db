-- 03_seed_data.sql
-- Synthetic Sample Data for Accounting & Field Inspection Workflows

INSERT INTO clients (company_name, contact_name, email, phone, account_status) VALUES
('Ozark Ridge Logistics', 'Marcus Vance', 'mvance@://example.com', '555-0101', 'Active'),
('Heartland Medical Imaging LLC', 'Dr. Elena Rostova', 'erostova@://example.com', '555-0102', 'Active'),
('Midwest Grain & Feed Co.', 'Caleb Sterling', 'csterling@://example.com', '555-0103', 'Active'),
('Show-Me Property Management', 'Hannah Abbott', 'habbott@://example.com', '555-0104', 'On Hold');

INSERT INTO staff (full_name, role, hourly_rate) VALUES
('Sarah Jenkins', 'Partner', 225.00),
('David Miller', 'Accountant', 135.00),
('Trevor Brooks', 'Inspector', 110.00),
('Maya Lin', 'Reviewer', 165.00),
('Claire Bennett', 'Intake Specialist', 65.00);

INSERT INTO service_types (service_name, department, base_fee) VALUES
('Corporate Tax Preparation (1120)', 'Accounting', 1500.00),
('Quarterly Bookkeeping & Reconciliation', 'Accounting', 650.00),
('Commercial Property Safety Inspection', 'Field Inspections', 475.00),
('Pre-Acquisition Compliance Audit', 'Advisory', 2200.00);

INSERT INTO work_orders (client_id, assigned_staff_id, service_id, status, priority, due_date, notes) VALUES
(1, 2, 1, 'In Progress', 'High', CURRENT_DATE + INTERVAL '5 days', 'Awaiting Q4 depreciation schedule from client.'),
(2, 4, 4, 'Quality Review', 'Urgent', CURRENT_DATE - INTERVAL '2 days', 'Final partner sign-off needed before closing.'),
(3, 3, 3, 'Intake', 'Normal', CURRENT_DATE + INTERVAL '12 days', 'Site inspection scheduled for north warehouse.'),
(1, 2, 2, 'Completed', 'Normal', CURRENT_DATE - INTERVAL '10 days', 'Reconciled all operating accounts; ready for billing.');

INSERT INTO time_entries (work_order_id, staff_id, hours_worked, is_billable, work_notes) VALUES
(1, 2, 4.50, TRUE, 'Imported general ledger and verified payroll tax filings.'),
(2, 4, 6.00, TRUE, 'Completed regulatory compliance checklist and risk summary.'),
(2, 1, 1.25, TRUE, 'Initial partner review of audit findings.'),
(4, 2, 3.00, TRUE, 'Completed bank statement reconciliation.');

-- Trigger test: Update status on Work Order #1 to automatically populate audit_logs
UPDATE work_orders SET status = 'Pending Client Info' WHERE work_order_id = 1;
