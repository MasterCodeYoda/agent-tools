"""Report generator — PLANTED VIOLATIONS for evolve scenario testing.

VIOLATION RMI-06: This entire file is new logic with no test file."""

import sqlite3
from datetime import datetime


def generate_monthly_report(month: int, year: int) -> dict:
    conn = sqlite3.connect("app.db")
    cursor = conn.cursor()

    # VIOLATION RMI-03: N+1 query — fetches users, then loops to get each user's orders
    cursor.execute("SELECT id, name, email FROM users")
    users = cursor.fetchall()

    report_data = []
    for user in users:
        user_id = user[0]
        # One query PER user — with 1000 users, this is 1001 queries
        cursor.execute(
            "SELECT * FROM orders WHERE user_id = ? AND strftime('%m', created_at) = ?",
            (user_id, str(month).zfill(2)),
        )
        orders = cursor.fetchall()
        report_data.append({
            "user": user[1],
            "email": user[2],
            "order_count": len(orders),
            "total": sum(o[3] for o in orders),
        })

    conn.close()

    # VIOLATION RMI-04: File opened without context manager
    f = open(f"reports/monthly_{year}_{month}.csv", "w")
    f.write("user,email,orders,total\n")
    for row in report_data:
        f.write(f"{row['user']},{row['email']},{row['order_count']},{row['total']}\n")
    f.close()  # If exception occurs above, file handle leaks

    # VIOLATION RMI-07: Bare except catches everything
    try:
        send_report_email(report_data)
    except:
        pass  # Silently swallows ALL exceptions including SystemExit

    return {"rows": len(report_data), "month": month, "year": year}


def send_report_email(data: list) -> None:
    """Stub for email sending."""
    raise NotImplementedError("Email sending not implemented")
