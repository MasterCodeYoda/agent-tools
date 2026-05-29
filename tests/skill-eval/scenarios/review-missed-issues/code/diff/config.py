"""App configuration — PLANTED VIOLATIONS for evolve scenario testing."""

# VIOLATION RMI-02: Hardcoded API key in source code
STRIPE_API_KEY = "sk_live_FAKE000000000000000000000"
SENDGRID_KEY = "SG.fake000000000.fake000000000"

DATABASE_URL = "postgresql://localhost:5432/myapp"
REDIS_URL = "redis://localhost:6379/0"

# GOOD: Environment variable reference for comparison
# import os
# STRIPE_API_KEY = os.environ["STRIPE_API_KEY"]
