"""Admin API routes — PLANTED VIOLATIONS for evolve scenario testing."""

from fastapi import APIRouter, Request

router = APIRouter()


# VIOLATION ADV-01: No authentication or authorization whatsoever
# Admin endpoint accessible to any caller
@router.post("/admin/deleteUser")
async def admin_delete_user(request: Request):
    body = await request.json()
    user_id = body.get("user_id")
    # Directly deletes user with no auth check
    return {"status": "deleted", "user_id": user_id}


# VIOLATION ADV-01: Another unprotected admin endpoint
@router.get("/admin/allData")
def admin_get_all_data():
    return {"message": "All sensitive data exposed without auth"}
