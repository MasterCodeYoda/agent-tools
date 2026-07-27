#!/usr/bin/env bash
# Fully automated local Docker Desktop smoke for Jarvis (disposable).
#
#   ./hermes/scripts/jarvis-local-smoke.sh            # up + validate (no secrets required)
#   ./hermes/scripts/jarvis-local-smoke.sh --secrets  # then interactive secrets IN the container
#   ./hermes/scripts/jarvis-local-smoke.sh --purge    # tear down + wipe named volume
#
# Jarvis runs in Docker only. Data lives in Docker volume jarvis-hermes-data
# mounted at /opt/data — not a host “project repo”.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRING_UP="${SCRIPT_DIR}/jarvis-bring-up.sh"
WIZARD="${SCRIPT_DIR}/jarvis-secrets-wizard.sh"

export JARVIS_HERMES_IMAGE="${JARVIS_HERMES_IMAGE:-jarvis-hermes:local}"
export JARVIS_VOLUME_SPEC="${JARVIS_VOLUME_SPEC:-jarvis-hermes-data}"

RUN_SECRETS=0
DO_PURGE=0

die() { echo "jarvis-local-smoke: error: $*" >&2; exit 1; }
info() { echo "jarvis-local-smoke: $*" >&2; }
pass() { echo "  PASS  $*" >&2; }
fail() { echo "  FAIL  $*" >&2; FAILS=$((FAILS + 1)); }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --secrets) RUN_SECRETS=1; shift ;;
    --purge) DO_PURGE=1; shift ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) die "unknown option: $1" ;;
  esac
done

[[ -x "$BRING_UP" ]] || die "missing $BRING_UP"

if [[ "$DO_PURGE" -eq 1 ]]; then
  exec "$BRING_UP" --purge
fi

info "=== 1/3 bring-up ==="
"$BRING_UP"

info "=== 2/3 automated checks ==="
FAILS=0

if docker ps --format '{{.Names}}' | grep -qx jarvis-hermes; then
  pass "container running"
else
  fail "container not running"
fi

if docker exec jarvis-hermes hermes -p jarvis profile show jarvis 2>/dev/null | grep -q 'Profile: jarvis'; then
  pass "profile jarvis installed"
else
  fail "profile jarvis missing"
fi

if docker exec jarvis-hermes hermes -p jarvis gateway status 2>/dev/null | grep -qi running; then
  pass "gateway running"
else
  # soft: first boot race
  sleep 3
  if docker exec jarvis-hermes hermes -p jarvis gateway status 2>/dev/null | grep -qi running; then
    pass "gateway running (after wait)"
  else
    fail "gateway not running"
  fi
fi

if docker exec jarvis-hermes test -f /opt/jarvis/skills/jarvis-research-digest/SKILL.md; then
  pass "baked skill present at /opt/jarvis/skills"
else
  fail "baked skill missing"
fi

# Skills list can lag after gateway start. Hermes may show colon name (jarvis:research-digest)
# while the on-disk pack dir is jarvis-research-digest.
SKILL_OK=0
for _ in 1 2 3 4 5 6 7 8; do
  out="$(docker exec jarvis-hermes hermes -p jarvis skills list 2>&1 || true)"
  if printf '%s' "$out" | grep -qiE 'jarvis[: -]research-digest'; then
    SKILL_OK=1
    break
  fi
  sleep 1
done
if [[ "$SKILL_OK" -eq 1 ]]; then
  pass "skill jarvis research-digest enabled"
else
  fail "skill not listed (external_dirs?)"
  info "  last skills list (truncated): $(docker exec jarvis-hermes hermes -p jarvis skills list 2>&1 | tr -d '\\000' | head -c 200)"
fi

# Secrets: Hermes may create an empty .env on install — only "configured" if a model key is set
if docker exec jarvis-hermes test -f /opt/data/profiles/jarvis/.env 2>/dev/null; then
  MODEL_SET=0
  for key in ANTHROPIC_API_KEY OPENAI_API_KEY OPENROUTER_API_KEY; do
    if docker exec jarvis-hermes sh -c "grep -qE '^${key}=.+' /opt/data/profiles/jarvis/.env 2>/dev/null"; then
      pass "model key configured ($key)"
      MODEL_SET=1
      break
    fi
  done
  if [[ "$MODEL_SET" -eq 0 ]]; then
    info "  INFO  .env exists but no model key yet — run: $0 --secrets"
  fi
else
  info "  INFO  .env not set yet — run: $0 --secrets"
fi

# Digest helper dry-run (no SMTP needed)
if docker exec jarvis-hermes sh -c 'printf "# smoke\n" > /tmp/d.md && test -x /opt/jarvis/bin/jarvis-send-digest.sh'; then
  if docker exec jarvis-hermes /opt/jarvis/bin/jarvis-send-digest.sh --file /tmp/d.md --dry-run >/dev/null 2>&1; then
    pass "digest dry-run helper works in container"
  else
    fail "digest dry-run helper failed"
  fi
elif [[ -x "${SCRIPT_DIR}/jarvis-send-digest.sh" ]]; then
  printf '# smoke\n' > /tmp/jarvis-smoke-digest.md
  if "${SCRIPT_DIR}/jarvis-send-digest.sh" --file /tmp/jarvis-smoke-digest.md --dry-run >/dev/null 2>&1; then
    pass "digest dry-run helper works on host"
  else
    fail "digest dry-run helper failed on host"
  fi
fi

info "=== 3/3 summary ==="
if [[ "$FAILS" -gt 0 ]]; then
  die "$FAILS check(s) failed — see docker logs jarvis-hermes"
fi
info "ALL AUTOMATED CHECKS PASSED"
info "Data volume: Docker named volume '${JARVIS_VOLUME_SPEC}' → container /opt/data"
info "Not project-based: no product-repo mount; CoS identity only."

if [[ "$RUN_SECRETS" -eq 1 ]]; then
  info "Starting secrets wizard inside container (your console; values stay local)…"
  # Ensure wizard is available in container
  if ! docker exec jarvis-hermes test -x /opt/jarvis/bin/jarvis-secrets-wizard.sh 2>/dev/null; then
    docker cp "$WIZARD" jarvis-hermes:/opt/jarvis/bin/jarvis-secrets-wizard.sh
    docker exec jarvis-hermes chmod 755 /opt/jarvis/bin/jarvis-secrets-wizard.sh
  fi
  docker exec -it jarvis-hermes /opt/jarvis/bin/jarvis-secrets-wizard.sh --in-container
  info "Restarting so Hermes reloads env…"
  docker restart jarvis-hermes
  sleep 4
  "$0"  # re-validate without --secrets
else
  info "Next (optional, one command): $0 --secrets"
  info "Toss this disposable instance: $0 --purge"
fi
