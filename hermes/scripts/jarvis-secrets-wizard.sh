#!/usr/bin/env bash
# Interactive secrets fill for Jarvis — runs on host or inside the container.
# Values never printed back. Prefer: ./hermes/scripts/jarvis-local-smoke.sh --secrets
#
#   jarvis-secrets-wizard.sh --in-container     # /opt/data/profiles/jarvis/.env
#   jarvis-secrets-wizard.sh --check            # set/missing only
#
set -euo pipefail

IN_CONTAINER=0
CHECK_ONLY=0
ENV_FILE=""

die() { echo "jarvis-secrets-wizard: error: $*" >&2; exit 1; }
info() { echo "jarvis-secrets-wizard: $*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --in-container) IN_CONTAINER=1; shift ;;
    --env-file) ENV_FILE="${2:-}"; shift 2 ;;
    --check) CHECK_ONLY=1; shift ;;
    --data-dir)
      # Back-compat: host bind-mount path
      ENV_FILE="${2:-}/profiles/jarvis/.env"
      shift 2
      ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
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
  echo "Model:   ANTHROPIC=$(mark ANTHROPIC_API_KEY) OPENAI=$(mark OPENAI_API_KEY) OPENROUTER=$(mark OPENROUTER_API_KEY)"
  echo "Email:   SMTP_HOST=$(mark JARVIS_SMTP_HOST) TO=$(mark JARVIS_DIGEST_TO)"
  echo "Slack:   BOT=$(mark SLACK_BOT_TOKEN) APP=$(mark SLACK_APP_TOKEN) USERS=$(mark SLACK_ALLOWED_USERS)"
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
    echo "# Inside container volume at $ENV_FILE — never commit"
    echo ""
    [[ -n "${CUR[ANTHROPIC_API_KEY]:-}" ]] && echo "ANTHROPIC_API_KEY=${CUR[ANTHROPIC_API_KEY]}"
    [[ -n "${CUR[OPENAI_API_KEY]:-}" ]] && echo "OPENAI_API_KEY=${CUR[OPENAI_API_KEY]}"
    [[ -n "${CUR[OPENROUTER_API_KEY]:-}" ]] && echo "OPENROUTER_API_KEY=${CUR[OPENROUTER_API_KEY]}"
    [[ -n "${CUR[JARVIS_SMTP_HOST]:-}" ]] && echo "JARVIS_SMTP_HOST=${CUR[JARVIS_SMTP_HOST]}"
    [[ -n "${CUR[JARVIS_SMTP_PORT]:-}" ]] && echo "JARVIS_SMTP_PORT=${CUR[JARVIS_SMTP_PORT]}"
    [[ -n "${CUR[JARVIS_SMTP_USER]:-}" ]] && echo "JARVIS_SMTP_USER=${CUR[JARVIS_SMTP_USER]}"
    [[ -n "${CUR[JARVIS_SMTP_PASSWORD]:-}" ]] && echo "JARVIS_SMTP_PASSWORD=${CUR[JARVIS_SMTP_PASSWORD]}"
    [[ -n "${CUR[JARVIS_SMTP_STARTTLS]:-}" ]] && echo "JARVIS_SMTP_STARTTLS=${CUR[JARVIS_SMTP_STARTTLS]}"
    [[ -n "${CUR[JARVIS_DIGEST_TO]:-}" ]] && echo "JARVIS_DIGEST_TO=${CUR[JARVIS_DIGEST_TO]}"
    [[ -n "${CUR[JARVIS_DIGEST_FROM]:-}" ]] && echo "JARVIS_DIGEST_FROM=${CUR[JARVIS_DIGEST_FROM]}"
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

info "Jarvis secrets (interactive). Agent lives in Docker; this file is on the data volume."
check_report
echo ""

if ask_yn "Configure model API key(s)?" "y"; then
  ask_val ANTHROPIC_API_KEY "ANTHROPIC_API_KEY" 1
  ask_val OPENAI_API_KEY "OPENAI_API_KEY" 1
  ask_val OPENROUTER_API_KEY "OPENROUTER_API_KEY" 1
fi
if ask_yn "Configure email SMTP (skip if not testing mail yet)?" "n"; then
  ask_val JARVIS_SMTP_HOST "SMTP host" 0
  ask_val JARVIS_SMTP_PORT "SMTP port" 0 "587"
  ask_val JARVIS_SMTP_USER "SMTP user" 0
  ask_val JARVIS_SMTP_PASSWORD "SMTP password" 1
  ask_val JARVIS_SMTP_STARTTLS "STARTTLS 1/0" 0 "1"
  ask_val JARVIS_DIGEST_TO "Digest To" 0
  ask_val JARVIS_DIGEST_FROM "Digest From" 0
fi
if ask_yn "Configure Slack (skip if not testing chat yet)?" "n"; then
  ask_val SLACK_BOT_TOKEN "SLACK_BOT_TOKEN" 1
  ask_val SLACK_APP_TOKEN "SLACK_APP_TOKEN" 1
  ask_val SLACK_ALLOWED_USERS "SLACK_ALLOWED_USERS" 0
  ask_val SLACK_HOME_CHANNEL "SLACK_HOME_CHANNEL" 0
fi

echo ""
if ask_yn "Write .env now?" "y"; then
  write_env
  check_report
else
  info "aborted"
  exit 1
fi
