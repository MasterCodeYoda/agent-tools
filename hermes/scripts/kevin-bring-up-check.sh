#!/usr/bin/env bash
# kevin-bring-up-check.sh — hard readiness bar for Kevin E4 bring-up
#
# Exit: 0 ok · 1 hard fail · 2 usage/misuse
# Soft gaps (missing .env, unset API keys) are reported as WARN, not fail.
#
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: kevin-bring-up-check.sh

Check hard readiness for Kevin Hermes bring-up:
  - hermes on PATH
  - profile "kevin" exists (hermes profile show)
  - managed skills dir present (default: $HOME/.hermes/skills)
  - preferred: .agent-tools-revision marker under skills
  - hermes -p kevin doctor runs (exit code ignored for soft advisories;
    fail only if the doctor command cannot be invoked)

Environment:
  HERMES_SKILLS_DIR   Override managed skills path (default: $HOME/.hermes/skills)

Does not invent NEXT, open gateway, or require live model auth.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SKILLS_DIR="${HERMES_SKILLS_DIR:-${HOME}/.hermes/skills}"
FAILS=0

ok() { echo "BRING-UP OK: $*"; }
warn() { echo "BRING-UP WARN: $*" >&2; }
fail() {
  echo "BRING-UP FAIL: $*" >&2
  FAILS=$((FAILS + 1))
}

# 1 — hermes CLI
if ! command -v hermes >/dev/null 2>&1; then
  fail "hermes not on PATH — install Hermes (upstream install script), then re-open shell"
else
  ver="$(hermes version 2>/dev/null | head -1 || true)"
  ok "hermes on PATH${ver:+ — ${ver}}"
fi

# 2 — profile kevin
if command -v hermes >/dev/null 2>&1; then
  if hermes profile show kevin >/dev/null 2>&1; then
    ok "profile kevin present"
    # Check for unexpanded placeholder
    profile_config="${HOME}/.hermes/profiles/kevin/config.yaml"
    if [[ -f "${profile_config}" ]] && grep -q '__HERMES_SKILLS_DIR__' "${profile_config}"; then
      fail "profile config contains unexpanded placeholder __HERMES_SKILLS_DIR__ — re-run ./scripts/apply-kevin-profile.sh --force -y"
    fi
  else
    fail "profile kevin missing — from software-factory: ./scripts/apply-kevin-profile.sh"
  fi
fi

# 3 — managed skills
if [[ ! -d "${SKILLS_DIR}" ]]; then
  fail "managed skills missing: ${SKILLS_DIR} — cd agent-tools && ./setup.sh"
else
  ok "managed skills dir: ${SKILLS_DIR}"
  rev="${SKILLS_DIR}/.agent-tools-revision"
  if [[ -f "${rev}" ]]; then
    # shellcheck disable=SC1090
    ok "agent-tools revision marker present"
    if grep -q 'publish-agent=hermes' "${rev}" 2>/dev/null; then
      ok "publish-agent=hermes"
    else
      warn "revision marker lacks publish-agent=hermes — confirm agent-tools hermes target"
    fi
  else
    warn "no ${rev} — skills dir exists but may not be agent-tools managed install"
  fi
fi

# 4 — doctor invocable (soft content is WARN only)
if command -v hermes >/dev/null 2>&1; then
  doctor_out="$(mktemp)"
  set +e
  hermes -p kevin doctor >"${doctor_out}" 2>&1
  doctor_ec=$?
  set -e
  # Hermes doctor often exits non-zero for advisories; treat "command ran" as hard pass
  # when we got doctor-shaped output.
  if grep -Eiq 'Hermes Doctor|Configuration Files|Python Environment' "${doctor_out}"; then
    ok "hermes -p kevin doctor ran (exit ${doctor_ec}; advisories may remain)"
    if grep -Eiq '\.env file missing|API Keys|not logged in|credentials stored' "${doctor_out}"; then
      warn "doctor reports soft gap (e.g. missing .env / keys / auth) — fill secrets before interactive chat"
    fi
  else
    fail "hermes -p kevin doctor did not produce expected output (exit ${doctor_ec})"
    sed -n '1,20p' "${doctor_out}" >&2 || true
  fi
  rm -f "${doctor_out}"
fi

# Soft: profile .env
if [[ -d "${HOME}/.hermes/profiles/kevin" && ! -f "${HOME}/.hermes/profiles/kevin/.env" ]]; then
  warn "profile .env missing — soft for bring-up; required for model chat"
fi

if [[ "${FAILS}" -gt 0 ]]; then
  echo "BRING-UP: ${FAILS} hard failure(s) — see FAIL lines and docs/runbooks/hermes-kevin.md" >&2
  exit 1
fi

echo "BRING-UP: hard readiness bar passed"
exit 0
