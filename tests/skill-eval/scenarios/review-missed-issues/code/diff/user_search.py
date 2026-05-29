"""User search endpoint — PLANTED VIOLATIONS for evolve scenario testing.

This file simulates a new addition in a changeset being reviewed."""

from fastapi import APIRouter, Request
import sqlite3

router = APIRouter()

DB_PATH = "app.db"


@router.get("/api/users/search")
def search_users(request: Request, q: str):
    # VIOLATION RMI-08: Debug print left in production code
    print(f"DEBUG: searching for {q}")
    print(f"DEBUG: request headers = {request.headers}")

    # VIOLATION RMI-01: SQL injection — user input interpolated into query
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE name LIKE '%{q}%' OR email LIKE '%{q}%'"
    cursor.execute(query)
    results = cursor.fetchall()
    conn.close()

    # VIOLATION RMI-05: Database query in route handler (framework layer)
    # Should use a repository in the infrastructure layer

    return {"users": results, "count": len(results)}


@router.get("/api/users/{user_id}/profile")
def get_user_profile(user_id: int):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    user = cursor.fetchone()
    conn.close()
    return {"user": user}
