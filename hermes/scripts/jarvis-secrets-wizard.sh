#!/usr/bin/env bash
# Interactive secrets fill for Jarvis — host or in-container.
# Values never printed back. Each section prints brief minting instructions first.
#
#   --in-container
#   --require-backup          full setup: backup PAT+repo required
#   --require-integrations    full setup: GitHub read + Linear + Jira required
#   --check
#
set -euo pipefail

IN_CONTAINER=0
CHECK_ONLY=0
REQUIRE_BACKUP=0
REQUIRE_INTEGRATIONS=0
ENV_FILE=""

die() { echo "jarvis-secrets-wizard: error: $*" >&2; exit 1; }
info() { echo "jarvis-secrets-wizard: $*" >&2; }
section() {
  echo "" >&2
  echo "────────────────────────────────────────────────────────" >&2
  echo "$*" >&2
  echo "────────────────────────────────────────────────────────" >&2
}
howto() {
  # brief minting instructions (stderr so not mixed with prompts oddly)
  while IFS= read -r line; do echo "  $line" >&2; done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --in-container) IN_CONTAINER=1; shift ;;
    --require-backup) REQUIRE_BACKUP=1; shift ;;
    --require-integrations) REQUIRE_INTEGRATIONS=1; shift ;;
    --env-file) ENV_FILE="${2:-}"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --data-dir) ENV_FILE="${2:-}/profiles/jarvis/.env"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

if [[ -z "$ENV_FILE" ]]; then
  if [[ "$IN_CONTAINER" -eq 1 ]] || [[ -d /opt/data/profiles/jarvis ]]; then
    ENV_FILE="/opt/data/profiles/jarvis/.env"
  else
    die "use --in-container (preferred) or --env-file PATH"
  fi
fi

mkdir -p "$(dirname "$ENV_FILE")"

declare -A CUR=()
if [[ -f "$ENV_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
      val="${val%\"}"; val="${val#\"}"
      CUR["$key"]="$val"
    fi
  done < "$ENV_FILE"
fi

has() { [[ -n "${CUR[$1]:-}" ]]; }
mark() { if has "$1"; then echo "set"; else echo "missing"; fi; }

xai_oauth_status() {
  # auth.json lives next to .env under the profile; never print tokens
  if command -v hermes >/dev/null 2>&1; then
    if hermes -p jarvis auth status xai-oauth 2>/dev/null | grep -qiE 'logged in|active|credential|token|ok|yes'; then
      echo "present"
      return 0
    fi
  fi
  local auth_json
  auth_json="$(dirname "$ENV_FILE")/auth.json"
  if [[ -f "$auth_json" ]] && grep -q 'xai-oauth' "$auth_json" 2>/dev/null; then
    echo "present"
    return 0
  fi
  echo "missing"
  return 1
}

check_report() {
  echo "Live env: $ENV_FILE"
  echo "  (values never printed)"
  echo "Model:    Grok-OAuth=$(xai_oauth_status 2>/dev/null || echo missing) XAI_KEY=$(mark XAI_API_KEY) ANTHROPIC=$(mark ANTHROPIC_API_KEY) OPENAI=$(mark OPENAI_API_KEY) OPENROUTER=$(mark OPENROUTER_API_KEY)"
  echo "Backup:   REPO=$(mark JARVIS_BACKUP_REPO) TOKEN=$(mark JARVIS_BACKUP_GITHUB_TOKEN)  # write one repo only"
  echo "GH read:  TOKEN=$(mark JARVIS_GITHUB_READ_TOKEN)  # OMG repos; NOT backup token"
  echo "Linear:   KEY=$(mark JARVIS_LINEAR_API_KEY)"
  echo "Jira:     URL=$(mark JARVIS_JIRA_BASE_URL) EMAIL=$(mark JARVIS_JIRA_EMAIL) TOKEN=$(mark JARVIS_JIRA_API_TOKEN)"
  echo "Email:    SMTP=$(mark JARVIS_SMTP_HOST) TO=$(mark JARVIS_DIGEST_TO)"
  echo "Slack:    BOT=$(mark SLACK_BOT_TOKEN) APP=$(mark SLACK_APP_TOKEN)"
}

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  check_report
  exit 0
fi

ask_yn() {
  local prompt="$1" def="${2:-n}" ans
  read -r -p "$prompt [$def]: " ans || true
  ans="${ans:-$def}"
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

ask_val() {
  local key="$1" prompt="$2" secret="${3:-0}" def="${4:-}"
  local cur="${CUR[$key]:-}" shown input=""
  if [[ -n "$cur" ]]; then shown="(set — enter keeps)"; elif [[ -n "$def" ]]; then shown="(default $def)"; else shown="(empty)"; fi
  if [[ "$secret" -eq 1 ]]; then
    read -r -s -p "$prompt $shown: " input || true
    echo "" >&2
  else
    read -r -p "$prompt $shown: " input || true
  fi
  if [[ -z "$input" ]]; then
    [[ -n "$cur" ]] && return 0
    [[ -n "$def" ]] && CUR["$key"]="$def"
    return 0
  fi
  CUR["$key"]="$input"
}

write_env() {
  local tmp
  tmp="$(mktemp)"
  {
    echo "# Jarvis live secrets — jarvis-secrets-wizard.sh"
    echo "# Volume path $ENV_FILE — never commit"
    echo "# Token split: BACKUP write ≠ GITHUB_READ ≠ Linear ≠ Jira"
    echo ""
    echo "# --- Model (prefer Grok OAuth via: hermes -p jarvis auth add xai-oauth --type oauth) ---"
    [[ -n "${CUR[XAI_API_KEY]:-}" ]] && echo "XAI_API_KEY=${CUR[XAI_API_KEY]}"
    [[ -n "${CUR[ANTHROPIC_API_KEY]:-}" ]] && echo "ANTHROPIC_API_KEY=${CUR[ANTHROPIC_API_KEY]}"
    [[ -n "${CUR[OPENAI_API_KEY]:-}" ]] && echo "OPENAI_API_KEY=${CUR[OPENAI_API_KEY]}"
    [[ -n "${CUR[OPENROUTER_API_KEY]:-}" ]] && echo "OPENROUTER_API_KEY=${CUR[OPENROUTER_API_KEY]}"
    echo ""
    echo "# --- Adaptive state backup (host cron; write one private repo) ---"
    [[ -n "${CUR[JARVIS_BACKUP_REPO]:-}" ]] && echo "JARVIS_BACKUP_REPO=${CUR[JARVIS_BACKUP_REPO]}"
    [[ -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" ]] && echo "JARVIS_BACKUP_GITHUB_TOKEN=${CUR[JARVIS_BACKUP_GITHUB_TOKEN]}"
    [[ -n "${CUR[JARVIS_BACKUP_BRANCH]:-}" ]] && echo "JARVIS_BACKUP_BRANCH=${CUR[JARVIS_BACKUP_BRANCH]}"
    [[ -n "${CUR[JARVIS_BACKUP_WORKDIR]:-}" ]] && echo "JARVIS_BACKUP_WORKDIR=${CUR[JARVIS_BACKUP_WORKDIR]}"
    echo ""
    echo "# --- OMG GitHub read (runtime; NOT backup token) ---"
    [[ -n "${CUR[JARVIS_GITHUB_READ_TOKEN]:-}" ]] && echo "JARVIS_GITHUB_READ_TOKEN=${CUR[JARVIS_GITHUB_READ_TOKEN]}"
    echo ""
    echo "# --- Linear read ---"
    [[ -n "${CUR[JARVIS_LINEAR_API_KEY]:-}" ]] && echo "JARVIS_LINEAR_API_KEY=${CUR[JARVIS_LINEAR_API_KEY]}"
    echo ""
    echo "# --- Jira read ---"
    [[ -n "${CUR[JARVIS_JIRA_BASE_URL]:-}" ]] && echo "JARVIS_JIRA_BASE_URL=${CUR[JARVIS_JIRA_BASE_URL]}"
    [[ -n "${CUR[JARVIS_JIRA_EMAIL]:-}" ]] && echo "JARVIS_JIRA_EMAIL=${CUR[JARVIS_JIRA_EMAIL]}"
    [[ -n "${CUR[JARVIS_JIRA_API_TOKEN]:-}" ]] && echo "JARVIS_JIRA_API_TOKEN=${CUR[JARVIS_JIRA_API_TOKEN]}"
    echo ""
    echo "# --- Email digest ---"
    [[ -n "${CUR[JARVIS_SMTP_HOST]:-}" ]] && echo "JARVIS_SMTP_HOST=${CUR[JARVIS_SMTP_HOST]}"
    [[ -n "${CUR[JARVIS_SMTP_PORT]:-}" ]] && echo "JARVIS_SMTP_PORT=${CUR[JARVIS_SMTP_PORT]}"
    [[ -n "${CUR[JARVIS_SMTP_USER]:-}" ]] && echo "JARVIS_SMTP_USER=${CUR[JARVIS_SMTP_USER]}"
    [[ -n "${CUR[JARVIS_SMTP_PASSWORD]:-}" ]] && echo "JARVIS_SMTP_PASSWORD=${CUR[JARVIS_SMTP_PASSWORD]}"
    [[ -n "${CUR[JARVIS_SMTP_STARTTLS]:-}" ]] && echo "JARVIS_SMTP_STARTTLS=${CUR[JARVIS_SMTP_STARTTLS]}"
    [[ -n "${CUR[JARVIS_DIGEST_TO]:-}" ]] && echo "JARVIS_DIGEST_TO=${CUR[JARVIS_DIGEST_TO]}"
    [[ -n "${CUR[JARVIS_DIGEST_FROM]:-}" ]] && echo "JARVIS_DIGEST_FROM=${CUR[JARVIS_DIGEST_FROM]}"
    echo ""
    echo "# --- Slack ---"
    [[ -n "${CUR[SLACK_BOT_TOKEN]:-}" ]] && echo "SLACK_BOT_TOKEN=${CUR[SLACK_BOT_TOKEN]}"
    [[ -n "${CUR[SLACK_APP_TOKEN]:-}" ]] && echo "SLACK_APP_TOKEN=${CUR[SLACK_APP_TOKEN]}"
    [[ -n "${CUR[SLACK_ALLOWED_USERS]:-}" ]] && echo "SLACK_ALLOWED_USERS=${CUR[SLACK_ALLOWED_USERS]}"
    [[ -n "${CUR[SLACK_ALLOWED_CHANNELS]:-}" ]] && echo "SLACK_ALLOWED_CHANNELS=${CUR[SLACK_ALLOWED_CHANNELS]}"
    [[ -n "${CUR[SLACK_HOME_CHANNEL]:-}" ]] && echo "SLACK_HOME_CHANNEL=${CUR[SLACK_HOME_CHANNEL]}"
  } > "$tmp"
  chmod 600 "$tmp"
  mv "$tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  info "wrote $ENV_FILE (mode 600)"
}

info "Jarvis secrets. Mint credentials before each section if you do not have them yet."
info "Tokens are split by job — never reuse the backup write PAT for org read."
check_report

# ── Model ──────────────────────────────────────────────────────────
section "1) Model — xAI Grok OAuth (recommended; Spectral/Wildwood style)"
howto <<'EOF'
Jarvis defaults to provider xai-oauth + model grok-4 (see hermes/jarvis-profile/config.yaml).

Preferred path = SuperGrok / Premium+ OAuth (device + browser PKCE). Tokens go to
profile auth.json — NOT .env (same idea as Spectral tools/dev/xai_login.py).

Mint / login (run in your terminal — needs interactive TTY + browser):

  docker exec -it jarvis-hermes hermes -p jarvis auth add xai-oauth --type oauth

  • Hermes prints a URL + code (or opens a browser).
  • Complete login on auth.x.ai with the SuperGrok / Premium+ account.
  • Tokens refresh automatically (short-lived access; refresh kept in auth.json).
  • Docs for remote/SSH-style flows:
    https://hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh

Optional: pick/confirm default model after login:
  docker exec -it jarvis-hermes hermes -p jarvis model

Fallback if you use BYOK API key instead of subscription OAuth:
  set XAI_API_KEY below and change profile model provider to "xai" (not xai-oauth).
Other providers (Anthropic/OpenAI/OpenRouter) are optional fall-through only.
EOF
if ask_yn "Have you completed (or will you complete next) Grok OAuth login for jarvis?" "y"; then
  info "If not already done, run in another terminal NOW:"
  info "  docker exec -it jarvis-hermes hermes -p jarvis auth add xai-oauth --type oauth"
  if ask_yn "Press y after OAuth succeeds so we can verify auth.json" "y"; then
    if xai_oauth_status >/dev/null 2>&1; then
      info "Grok OAuth: present (auth.json / hermes status)"
    else
      info "Grok OAuth not detected yet — complete the docker exec auth add command, then re-run wizard or continue and fix later"
    fi
  fi
fi
if ask_yn "Also set API-key fallbacks (XAI_API_KEY / Anthropic / OpenAI / OpenRouter)?" "n"; then
  ask_val XAI_API_KEY "XAI_API_KEY (BYOK; not needed if OAuth works)" 1
  ask_val ANTHROPIC_API_KEY "ANTHROPIC_API_KEY" 1
  ask_val OPENAI_API_KEY "OPENAI_API_KEY" 1
  ask_val OPENROUTER_API_KEY "OPENROUTER_API_KEY" 1
fi

# ── Backup write ───────────────────────────────────────────────────
section "2) Adaptive-state backup (GitHub write — ONE private repo only)"
howto <<'EOF'
Purpose: nightly commit of non-secret CoS state (digests/notes) for restore + skill evolution.
Do NOT use this token for OMG org repo access.

Mint:
  1. Create empty private repo (e.g. org/jarvis-state) on GitHub if it does not exist.
  2. GitHub → Settings → Developer settings → Fine-grained personal access tokens → Generate.
  3. Resource owner: your user/org. Repository access: Only select repositories → jarvis-state.
  4. Permissions: Repository → Contents: Read and write. (Metadata read is automatic.)
  5. Generate and copy the token once (ghp_… / github_pat_…).
EOF
if [[ "$REQUIRE_BACKUP" -eq 1 ]]; then
  info "Required for full durable setup."
  ask_val JARVIS_BACKUP_REPO "JARVIS_BACKUP_REPO (https://github.com/ORG/jarvis-state.git)" 0
  ask_val JARVIS_BACKUP_GITHUB_TOKEN "JARVIS_BACKUP_GITHUB_TOKEN" 1
  ask_val JARVIS_BACKUP_BRANCH "JARVIS_BACKUP_BRANCH" 0 "main"
  [[ -n "${CUR[JARVIS_BACKUP_REPO]:-}" && -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" ]] \
    || die "backup repo + token required — mint them using the steps above, then re-run"
else
  if ask_yn "Configure adaptive-state git backup now?" "y"; then
    ask_val JARVIS_BACKUP_REPO "JARVIS_BACKUP_REPO" 0
    ask_val JARVIS_BACKUP_GITHUB_TOKEN "JARVIS_BACKUP_GITHUB_TOKEN" 1
    ask_val JARVIS_BACKUP_BRANCH "JARVIS_BACKUP_BRANCH" 0 "main"
  fi
fi

# ── Research correlation integrations ──────────────────────────────
section "3) Research correlation — OMG GitHub READ (separate token)"
howto <<'EOF'
Purpose: Jarvis runtime read of selected OMG repos (familiarity / digests). Not backup.

Mint (fine-grained PAT v1; GitHub App later if preferred):
  1. Fine-grained PAT → Repository access: Only select repositories → choose OMG repos.
  2. Permissions: Contents: Read-only. (Optional: Issues/Metadata read if you want.)
  3. Do NOT grant this token Contents:write. Do NOT reuse the backup token.
EOF
if [[ "$REQUIRE_INTEGRATIONS" -eq 1 ]]; then
  info "Required for full CoS setup."
  ask_val JARVIS_GITHUB_READ_TOKEN "JARVIS_GITHUB_READ_TOKEN" 1
  [[ -n "${CUR[JARVIS_GITHUB_READ_TOKEN]:-}" ]] || die "JARVIS_GITHUB_READ_TOKEN required — mint with steps above"
  if [[ -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" && "${CUR[JARVIS_GITHUB_READ_TOKEN]}" == "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]}" ]]; then
    die "Read token must differ from backup write token — create a second fine-grained PAT"
  fi
else
  if ask_yn "Configure OMG GitHub read access now?" "y"; then
    ask_val JARVIS_GITHUB_READ_TOKEN "JARVIS_GITHUB_READ_TOKEN" 1
  fi
fi

section "4) Research correlation — Linear READ"
howto <<'EOF'
Purpose: correlate digests/research with Linear issues (read-only).

Mint:
  1. Linear → Settings → Account → Security & access → Personal API keys
     (or https://linear.app/settings/account/security )
  2. Create key; label e.g. jarvis-cos-read. Copy once.
  3. Prefer a key used only for Jarvis; revoke if leaked.
EOF
if [[ "$REQUIRE_INTEGRATIONS" -eq 1 ]]; then
  ask_val JARVIS_LINEAR_API_KEY "JARVIS_LINEAR_API_KEY" 1
  [[ -n "${CUR[JARVIS_LINEAR_API_KEY]:-}" ]] || die "JARVIS_LINEAR_API_KEY required — mint with steps above"
else
  if ask_yn "Configure Linear read now?" "y"; then
    ask_val JARVIS_LINEAR_API_KEY "JARVIS_LINEAR_API_KEY" 1
  fi
fi

section "5) Research correlation — Jira Cloud READ"
howto <<'EOF'
Purpose: correlate digests/research with Jira issues (read-only usage).

Mint:
  1. API token: https://id.atlassian.com/manage-profile/security/api-tokens → Create API token
     Label e.g. jarvis-cos-read. Copy once.
  2. Base URL: your site, e.g. https://YOUR-DOMAIN.atlassian.net  (no path suffix)
  3. Email: the Atlassian account email that owns the token
  4. Product access: that account needs browse permission on the projects Jarvis should see.
EOF
if [[ "$REQUIRE_INTEGRATIONS" -eq 1 ]]; then
  ask_val JARVIS_JIRA_BASE_URL "JARVIS_JIRA_BASE_URL (https://….atlassian.net)" 0
  ask_val JARVIS_JIRA_EMAIL "JARVIS_JIRA_EMAIL" 0
  ask_val JARVIS_JIRA_API_TOKEN "JARVIS_JIRA_API_TOKEN" 1
  [[ -n "${CUR[JARVIS_JIRA_BASE_URL]:-}" && -n "${CUR[JARVIS_JIRA_EMAIL]:-}" && -n "${CUR[JARVIS_JIRA_API_TOKEN]:-}" ]] \
    || die "Jira URL + email + API token required — mint with steps above"
else
  if ask_yn "Configure Jira read now?" "y"; then
    ask_val JARVIS_JIRA_BASE_URL "JARVIS_JIRA_BASE_URL" 0
    ask_val JARVIS_JIRA_EMAIL "JARVIS_JIRA_EMAIL" 0
    ask_val JARVIS_JIRA_API_TOKEN "JARVIS_JIRA_API_TOKEN" 1
  fi
fi

# ── Optional channels ──────────────────────────────────────────────
section "6) Email SMTP (optional until testing digests)"
howto <<'EOF'
Mint depends on provider (Gmail app password, SES SMTP user, etc.).
Need: host, port (often 587), user, password, From and To addresses.
EOF
if ask_yn "Configure email SMTP now?" "n"; then
  ask_val JARVIS_SMTP_HOST "SMTP host" 0
  ask_val JARVIS_SMTP_PORT "SMTP port" 0 "587"
  ask_val JARVIS_SMTP_USER "SMTP user" 0
  ask_val JARVIS_SMTP_PASSWORD "SMTP password" 1
  ask_val JARVIS_SMTP_STARTTLS "STARTTLS 1/0" 0 "1"
  ask_val JARVIS_DIGEST_TO "Digest To" 0
  ask_val JARVIS_DIGEST_FROM "Digest From" 0
fi

section "7) Slack Socket Mode (optional until testing chat)"
howto <<'EOF'
Mint:
  1. https://api.slack.com/apps → Create app (manifest) branded Jarvis — see docs/agents/runbooks/jarvis-slack.md
  2. Enable Socket Mode → create App-Level Token (xapp-…) with connections:write
  3. OAuth → Bot token (xoxb-…) after install to workspace
  4. Your Slack member ID for SLACK_ALLOWED_USERS (profile → … → Copy member ID)
EOF
if ask_yn "Configure Slack now?" "n"; then
  ask_val SLACK_BOT_TOKEN "SLACK_BOT_TOKEN (xoxb-…)" 1
  ask_val SLACK_APP_TOKEN "SLACK_APP_TOKEN (xapp-…)" 1
  ask_val SLACK_ALLOWED_USERS "SLACK_ALLOWED_USERS (member IDs)" 0
  ask_val SLACK_HOME_CHANNEL "SLACK_HOME_CHANNEL (optional C…)" 0
fi

echo ""
if ask_yn "Write .env now?" "y"; then
  write_env
  if [[ "$REQUIRE_BACKUP" -eq 1 ]]; then
    has JARVIS_BACKUP_REPO && has JARVIS_BACKUP_GITHUB_TOKEN || die "backup fields missing after write"
  fi
  if [[ "$REQUIRE_INTEGRATIONS" -eq 1 ]]; then
    has JARVIS_GITHUB_READ_TOKEN && has JARVIS_LINEAR_API_KEY \
      && has JARVIS_JIRA_BASE_URL && has JARVIS_JIRA_EMAIL && has JARVIS_JIRA_API_TOKEN \
      || die "research integration fields missing after write"
  fi
  if has JARVIS_BACKUP_GITHUB_TOKEN && has JARVIS_GITHUB_READ_TOKEN; then
    if [[ "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]}" == "${CUR[JARVIS_GITHUB_READ_TOKEN]}" ]]; then
      die "backup and read GitHub tokens must differ"
    fi
  fi
  check_report
else
  info "aborted"
  exit 1
fi
