"""User API routes — PLANTED VIOLATIONS for evolve scenario testing."""

from fastapi import APIRouter, Request

router = APIRouter()

# In-memory store for simplicity
_users = {
    1: {"id": 1, "name": "Alice", "email": "alice@example.com", "role": "admin"},
    2: {"id": 2, "name": "Bob", "email": "bob@example.com", "role": "user"},
}
_next_id = 3


# VIOLATION ADV-02: Verb in resource name — should be GET /users
@router.get("/getUsers")
def get_users():
    # VIOLATION ADV-04: No pagination — returns all users
    return {"users": list(_users.values())}


# VIOLATION ADV-02: Verb in resource name — should be POST /users
# VIOLATION ADV-05: No input validation — accepts arbitrary dict
# VIOLATION ADV-06: Returns 200 instead of 201 Created
@router.post("/createUser")
async def create_user(request: Request):
    global _next_id
    body = await request.json()  # No schema validation at all

    user = {
        "id": _next_id,
        "name": body.get("name"),
        "email": body.get("email"),
        "role": body.get("role", "user"),
        **{k: v for k, v in body.items()},  # Passes through arbitrary fields
    }
    _users[_next_id] = user
    _next_id += 1

    return {"status": "ok", "user": user}  # 200, not 201


# VIOLATION ADV-07: BOLA — no authorization check
# Any authenticated user can access any other user's data
@router.get("/users/{user_id}")
def get_user(user_id: int):
    # No check that the requesting user has permission to view this user
    user = _users.get(user_id)
    if not user:
        # VIOLATION ADV-03: Inconsistent error format (plain string)
        return "User not found"
    return user


@router.put("/users/{user_id}")
async def update_user(user_id: int, request: Request):
    body = await request.json()
    if user_id not in _users:
        # VIOLATION ADV-03: Different error format ({"detail": ...})
        return {"detail": "User not found"}
    _users[user_id].update(body)
    return _users[user_id]


# VIOLATION ADV-06: Returns 200 instead of 204 No Content
@router.delete("/users/{user_id}")
def delete_user(user_id: int):
    if user_id not in _users:
        # VIOLATION ADV-03: Yet another error format ({"error": ...})
        return {"error": "Not found"}
    del _users[user_id]
    return {"status": "deleted"}


# GOOD: Properly designed endpoint for comparison
@router.get("/health")
def health_check():
    return {"status": "healthy"}
