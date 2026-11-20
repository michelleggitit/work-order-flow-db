-- 02_views_triggers.sql
-- Automated Status Audit Trigger & Executive Reporting Views

-- 1. Trigger Function: Automatically log every work-order status change
CREATE OR REPLACE FUNCTION log_work_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_logs (work_order_id, old_status, new_status, changed_at)
        VALUES (NEW.work_order_id, OLD.status, NEW.status, CURRENT_TIMESTAMP);
        
        NEW.updated_at := CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_work_order_status_audit
BEFORE UPDATE ON work_orders
FOR EACH ROW
EXECUTE FUNCTION log_work_order_status_change();

-- 2. Reporting View: Active Office Dashboard
CREATE OR REPLACE VIEW vw_active_work_orders AS
SELECT 
    wo.work_order_id,
    c.company_name AS client,
    st.service_name AS service,
    st.department,
    s.full_name AS assigned_to,
    wo.status,
    wo.priority,
    wo.due_date,
    CASE 
        WHEN wo.due_date < CURRENT_DATE AND wo.status NOT IN ('Completed', 'Billed') THEN 'OVERDUE'
        ELSE 'On Track'
    END AS schedule_status
FROM work_orders wo
JOIN clients c ON wo.client_id = c.client_id
JOIN service_types st ON wo.service_id = st.service_id
LEFT JOIN staff s ON wo.assigned_staff_id = s.staff_id
WHERE wo.status <> 'Billed'
ORDER BY wo.due_date ASC;

-- 3. Reporting View: Staff Utilization & Billable Hours
CREATE OR REPLACE VIEW vw_staff_utilization AS
SELECT 
    s.staff_id,
    s.full_name,
    s.role,
    COUNT(DISTINCT te.work_order_id) AS active_orders_worked,
    COALESCE(SUM(te.hours_worked), 0) AS total_hours,
    COALESCE(SUM(CASE WHEN te.is_billable THEN te.hours_worked ELSE 0 END), 0) AS billable_hours,
    COALESCE(SUM(CASE WHEN te.is_billable THEN te.hours_worked * s.hourly_rate ELSE 0 END), 0) AS billable_value
FROM staff s
LEFT JOIN time_entries te ON s.staff_id = te.staff_id
GROUP BY s.staff_id, s.full_name, s.role
ORDER BY billable_value DESC;
