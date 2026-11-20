import streamlit as st
import pandas as pd
from datetime import date, timedelta

st.set_page_config(
    page_title="Work-Order Flow Manager",
    page_icon="📋",
    layout="wide"
)

# Initialize session state with synthetic data matching sql/03_seed_data.sql
if "work_orders" not in st.session_state:
    st.session_state.work_orders = pd.DataFrame([
        {
            "ID": 101,
            "Client": "Ozark Ridge Logistics",
            "Service": "Corporate Tax Preparation (1120)",
            "Department": "Accounting",
            "Assigned To": "David Miller",
            "Status": "Pending Client Info",
            "Priority": "High",
            "Due Date": date.today() + timedelta(days=5),
            "Notes": "Awaiting Q4 depreciation schedule from client."
        },
        {
            "ID": 102,
            "Client": "Heartland Medical Imaging LLC",
            "Service": "Pre-Acquisition Compliance Audit",
            "Department": "Advisory",
            "Assigned To": "Maya Lin",
            "Status": "Quality Review",
            "Priority": "Urgent",
            "Due Date": date.today() - timedelta(days=2),
            "Notes": "Final partner sign-off needed before closing."
        },
        {
            "ID": 103,
            "Client": "Midwest Grain & Feed Co.",
            "Service": "Commercial Property Safety Inspection",
            "Department": "Field Inspections",
            "Assigned To": "Trevor Brooks",
            "Status": "Intake",
            "Priority": "Normal",
            "Due Date": date.today() + timedelta(days=12),
            "Notes": "Site inspection scheduled for north warehouse."
        },
        {
            "ID": 104,
            "Client": "Ozark Ridge Logistics",
            "Service": "Quarterly Bookkeeping & Reconciliation",
            "Department": "Accounting",
            "Assigned To": "David Miller",
            "Status": "Completed",
            "Priority": "Normal",
            "Due Date": date.today() - timedelta(days=10),
            "Notes": "Reconciled all operating accounts; ready for billing."
        }
    ])

if "audit_logs" not in st.session_state:
    st.session_state.audit_logs = [
        {"Work Order ID": 101, "Old Status": "In Progress", "New Status": "Pending Client Info", "Timestamp": "Initial Seed"}
    ]

# Header
st.title("📋 Accounting & Inspection Work-Order Flow")
st.caption("Interactive intake form, status tracking, and automated audit log demo")

# Top KPI Summary Row
df = st.session_state.work_orders
overdue_count = len(df[(df["Due Date"] < date.today()) & (~df["Status"].isin(["Completed", "Billed"]))])

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Work Orders", len(df))
col2.metric("Active / Open", len(df[~df["Status"].isin(["Completed", "Billed"])]))
col3.metric("Overdue Orders", overdue_count)
col4.metric("Audit Log Events", len(st.session_state.audit_logs))

st.divider()

# Tabs for Intake Form, Live Queue, and Audit Trail
tab1, tab2, tab3 = st.tabs(["➕ New Work-Order Intake", "📊 Active Workflow Queue", "🛡️ Automated Audit Trail"])

with tab1:
    st.subheader("Submit New Client Work Order")
    with st.form("intake_form", clear_on_submit=True):
        c1, c2 = st.columns(2)
        client = c1.selectbox("Client", [
            "Ozark Ridge Logistics",
            "Heartland Medical Imaging LLC",
            "Midwest Grain & Feed Co.",
            "Show-Me Property Management"
        ])
        service = c2.selectbox("Service Type", [
            "Corporate Tax Preparation (1120)",
            "Quarterly Bookkeeping & Reconciliation",
            "Commercial Property Safety Inspection",
            "Pre-Acquisition Compliance Audit"
        ])
        
        c3, c4, c5 = st.columns(3)
        assigned_to = c3.selectbox("Assign To", ["David Miller", "Trevor Brooks", "Maya Lin", "Sarah Jenkins"])
        priority = c4.selectbox("Priority", ["Low", "Normal", "High", "Urgent"], index=1)
        due_date = c5.date_input("Target Due Date", value=date.today() + timedelta(days=7))
        
        notes = st.text_area("Intake Notes & Scope Details", placeholder="Enter client instructions, missing documents, or site access info...")
        submitted = st.form_submit_button("Create Work Order", type="primary")

        if submitted:
            dept_map = {
                "Corporate Tax Preparation (1120)": "Accounting",
                "Quarterly Bookkeeping & Reconciliation": "Accounting",
                "Commercial Property Safety Inspection": "Field Inspections",
                "Pre-Acquisition Compliance Audit": "Advisory"
            }
            new_id = int(df["ID"].max()) + 1
            new_row = pd.DataFrame([{
                "ID": new_id,
                "Client": client,
                "Service": service,
                "Department": dept_map[service],
                "Assigned To": assigned_to,
                "Status": "Intake",
                "Priority": priority,
                "Due Date": due_date,
                "Notes": notes if notes else "Standard intake."
            }])
            st.session_state.work_orders = pd.concat([st.session_state.work_orders, new_row], ignore_index=True)
            st.success(f"Work Order #{new_id} created for {client}!")

with tab2:
    st.subheader("Live Office Queue & Status Updates")
    
    # Filter controls
    dept_filter = st.multiselect(
        "Filter by Department",
        options=df["Department"].unique().tolist(),
        default=df["Department"].unique().tolist()
    )
    filtered_df = df[df["Department"].isin(dept_filter)].copy()
    filtered_df["Schedule"] = filtered_df.apply(
        lambda r: "⚠️ OVERDUE" if (r["Due Date"] < date.today() and r["Status"] not in ["Completed", "Billed"]) else "✅ On Track",
        axis=1
    )
    st.dataframe(filtered_df, use_container_width=True, hide_index=True)

    # Quick Status Transition Box (Simulates SQL Trigger)
    st.markdown("#### Update Work-Order Status")
    u1, u2, u3 = st.columns([1, 2, 1])
    selected_id = u1.selectbox("Work Order ID", df["ID"].tolist())
    new_status = u2.selectbox("New Status", ["Intake", "In Progress", "Pending Client Info", "Quality Review", "Completed", "Billed"])
    if u3.button("Update Status"):
        idx = df.index[df["ID"] == selected_id][0]
        old_status = df.at[idx, "Status"]
        if old_status != new_status:
            st.session_state.work_orders.at[idx, "Status"] = new_status
            st.session_state.audit_logs.append({
                "Work Order ID": selected_id,
                "Old Status": old_status,
                "New Status": new_status,
                "Timestamp": pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
            })
            st.rerun()

with tab3:
    st.subheader("Status Transition Audit Log")
    st.write("Mirrors the `trg_work_order_status_audit` PostgreSQL trigger in `sql/02_views_triggers.sql`.")
    st.table(pd.DataFrame(st.session_state.audit_logs))
