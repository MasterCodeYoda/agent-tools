#!/usr/bin/env bash
# Interactive secrets fill for Jarvis — host or in-container.
# Values never printed back.
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

check_report() {
  echo "Live env: $ENV_FILE"
  echo "  (values never printed)"
  echo "Model:    ANTHROPIC=$(mark ANTHROPIC_API_KEY) OPENAI=$(mark OPENAI_API_KEY) OPENROUTER=$(mark OPENROUTER_API_KEY)"
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
    echo "# --- Model ---"
    [[ -n "${CUR[ANTHROPIC_API_KEY]:-}" ]] && echo "ANTHROPIC_API_KEY=${CUR[ANTHROPIC_API_KEY]}"
    [[ -n "${CUR[OPENAI_API_KEY]:-}" ]] && echo "OPENAI_API_KEY=${CUR[OPENAI_API_KEY]}"
    [[ -n "${CUR[OPENROUTER_API_KEY]:-}" ]] && echo "OPENROUTER_API_KEY=${CUR[OPENROUTER_API_KEY]}"
    echo ""
    echo "# --- Adaptive state backup (host cron only; write one private repo) ---"
    [[ -n "${CUR[JARVIS_BACKUP_REPO]:-}" ]] && echo "JARVIS_BACKUP_REPO=${CUR[JARVIS_BACKUP_REPO]}"
    [[ -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" ]] && echo "JARVIS_BACKUP_GITHUB_TOKEN=${CUR[JARVIS_BACKUP_GITHUB_TOKEN]}"
    [[ -n "${CUR[JARVIS_BACKUP_BRANCH]:-}" ]] && echo "JARVIS_BACKUP_BRANCH=${CUR[JARVIS_BACKUP_BRANCH]}"
    [[ -n "${CUR[JARVIS_BACKUP_WORKDIR]:-}" ]] && echo "JARVIS_BACKUP_WORKDIR=${CUR[JARVIS_BACKUP_WORKDIR]}"
    echo ""
    echo "# --- OMG GitHub read (runtime CoS; NOT backup token) ---"
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

info "Jarvis secrets. Tokens are split by job — never reuse backup write PAT for org read."
check_report
echo ""

if ask_yn "Configure model API key(s)?" "y"; then
  ask_val ANTHROPIC_API_KEY "ANTHROPIC_API_KEY" 1
  ask_val OPENAI_API_KEY "OPENAI_API_KEY" 1
  ask_val OPENROUTER_API_KEY "OPENROUTER_API_KEY" 1
fi

if [[ "$REQUIRE_BACKUP" -eq 1 ]]; then
  info "Backup (required): private repo + fine-grained PAT with contents:write to THAT repo only."
  ask_val JARVIS_BACKUP_REPO "JARVIS_BACKUP_REPO (https://github.com/org/jarvis-state.git)" 0
  ask_val JARVIS_BACKUP_GITHUB_TOKEN "JARVIS_BACKUP_GITHUB_TOKEN" 1
  ask_val JARVIS_BACKUP_BRANCH "JARVIS_BACKUP_BRANCH" 0 "main"
  [[ -n "${CUR[JARVIS_BACKUP_REPO]:-}" && -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" ]] \
    || die "backup repo + token required"
else
  if ask_yn "Configure adaptive-state git backup?" "y"; then
    ask_val JARVIS_BACKUP_REPO "JARVIS_BACKUP_REPO" 0
    ask_val JARVIS_BACKUP_GITHUB_TOKEN "JARVIS_BACKUP_GITHUB_TOKEN" 1
    ask_val JARVIS_BACKUP_BRANCH "JARVIS_BACKUP_BRANCH" 0 "main"
  fi
fi

# Research correlation integrations — separate credentials
if [[ "$REQUIRE_INTEGRATIONS" -eq 1 ]]; then
  info "Research correlation (required for full CoS setup): read-only GitHub (OMG) + Linear + Jira."
  info "JARVIS_GITHUB_READ_TOKEN must NOT be the backup write token."
  ask_val JARVIS_GITHUB_READ_TOKEN "JARVIS_GITHUB_READ_TOKEN (read selected OMG repos)" 1
  ask_val JARVIS_LINEAR_API_KEY "JARVIS_LINEAR_API_KEY (Linear read)" 1
  ask_val JARVIS_JIRA_BASE_URL "JARVIS_JIRA_BASE_URL (https://….atlassian.net)" 0
  ask_val JARVIS_JIRA_EMAIL "JARVIS_JIRA_EMAIL" 0
  ask_val JARVIS_JIRA_API_TOKEN "JARVIS_JIRA_API_TOKEN" 1
  [[ -n "${CUR[JARVIS_GITHUB_READ_TOKEN]:-}" ]] || die "JARVIS_GITHUB_READ_TOKEN required"
  [[ -n "${CUR[JARVIS_LINEAR_API_KEY]:-}" ]] || die "JARVIS_LINEAR_API_KEY required"
  [[ -n "${CUR[JARVIS_JIRA_BASE_URL]:-}" && -n "${CUR[JARVIS_JIRA_EMAIL]:-}" && -n "${CUR[JARVIS_JIRA_API_TOKEN]:-}" ]] \
    || die "Jira base URL + email + API token required"
  if [[ -n "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]:-}" && "${CUR[JARVIS_GITHUB_READ_TOKEN]}" == "${CUR[JARVIS_BACKUP_GITHUB_TOKEN]}" ]]; then
    die "JARVIS_GITHUB_READ_TOKEN must differ from JARVIS_BACKUP_GITHUB_TOKEN (split credentials)"
  fi
else
  if ask_yn "Configure OMG GitHub read access (separate from backup)?" "y"; then
    ask_val JARVIS_GITHUB_READ_TOKEN "JARVIS_GITHUB_READ_TOKEN" 1
  fi
  if ask_yn "Configure Linear read-only?" "y"; then
    ask_val JARVIS_LINEAR_API_KEY "JARVIS_LINEAR_API_KEY" 1
  fi
  if ask_yn "Configure Jira read-only?" "y"; then
    ask_val JARVIS_JIRA_BASE_URL "JARVIS_JIRA_BASE_URL" 0
    ask_val JARVIS_JIRA_EMAIL "JARVIS_JIRA_EMAIL" 0
    ask_val JARVIS_JIRA_API_TOKEN "JARVIS_JIRA_API_TOKEN" 1
  fi
fi

if ask_yn "Configure email SMTP?" "n"; then
  ask_val JARVIS_SMTP_HOST "SMTP host" 0
  ask_val JARVIS_SMTP_PORT "SMTP port" 0 "587"
  ask_val JARVIS_SMTP_USER "SMTP user" 0
  ask_val JARVIS_SMTP_PASSWORD "SMTP password" 1
  ask_val JARVIS_SMTP_STARTTLS "STARTTLS 1/0" 0 "1"
  ask_val JARVIS_DIGEST_TO "Digest To" 0
  ask_val JARVIS_DIGEST_FROM "Digest From" 0
fi
if ask_yn "Configure Slack?" "n"; then
  ask_val SLACK_BOT_TOKEN "SLACK_BOT_TOKEN" 1
  ask_val SLACK_APP_TOKEN "SLACK_APP_TOKEN" 1
  ask_val SLACK_ALLOWED_USERS "SLACK_ALLOWED_USERS" 0
  ask_val SLACK_HOME_CHANNEL "SLACK_HOME_CHANNEL" 0
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
  check_report
else
  info "aborted"
  exit 1
fi
