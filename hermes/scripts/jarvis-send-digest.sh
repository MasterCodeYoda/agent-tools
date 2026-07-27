#!/usr/bin/env bash
# Send or dry-run a Jarvis research digest via SMTP env (names in jarvis-profile .env.template).
# Usage:
#   jarvis-send-digest.sh --file path/to/digest.md [--dry-run]
# Exit 2 if required email env missing and not dry-run.
set -euo pipefail

FILE=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      echo "Usage: $0 --file DIGEST.md [--dry-run]"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$FILE" && -f "$FILE" ]] || { echo "error: --file required and must exist" >&2; exit 2; }

need=(JARVIS_SMTP_HOST JARVIS_SMTP_PORT JARVIS_SMTP_USER JARVIS_SMTP_PASSWORD JARVIS_DIGEST_TO JARVIS_DIGEST_FROM)
missing=0
for v in "${need[@]}"; do
  if [[ -z "${!v:-}" ]]; then
    echo "missing env: $v" >&2
    missing=1
  fi
done

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry-run: would send $(basename "$FILE") to ${JARVIS_DIGEST_FROM:-?} → ${JARVIS_DIGEST_TO:-?}"
  echo "dry-run: path=$FILE bytes=$(wc -c <"$FILE" | tr -d ' ')"
  exit 0
fi

if [[ "$missing" -eq 1 ]]; then
  echo "error: email capability incomplete — set SMTP + digest env or pass --dry-run" >&2
  exit 2
fi

# Prefer Python stdlib smtplib (no extra deps)
export JARVIS_DIGEST_FILE="$FILE"
python3 - <<'PY'
import os, smtplib, ssl, sys
from email.message import EmailMessage
from pathlib import Path

host = os.environ["JARVIS_SMTP_HOST"]
port = int(os.environ.get("JARVIS_SMTP_PORT", "587"))
user = os.environ["JARVIS_SMTP_USER"]
password = os.environ["JARVIS_SMTP_PASSWORD"]
to_addr = os.environ["JARVIS_DIGEST_TO"]
from_addr = os.environ["JARVIS_DIGEST_FROM"]
starttls = os.environ.get("JARVIS_SMTP_STARTTLS", "1") not in ("0", "false", "no")
body = Path(os.environ["JARVIS_DIGEST_FILE"]).read_text(encoding="utf-8")
day = Path(os.environ["JARVIS_DIGEST_FILE"]).stem

msg = EmailMessage()
msg["Subject"] = f"Jarvis digest — {day}"
msg["From"] = from_addr
msg["To"] = to_addr
msg.set_content(body)

if starttls:
    ctx = ssl.create_default_context()
    with smtplib.SMTP(host, port, timeout=60) as s:
        s.ehlo()
        s.starttls(context=ctx)
        s.ehlo()
        s.login(user, password)
        s.send_message(msg)
else:
    with smtplib.SMTP_SSL(host, port, timeout=60) as s:
        s.login(user, password)
        s.send_message(msg)
print(f"sent digest to {to_addr}", file=sys.stderr)
PY
