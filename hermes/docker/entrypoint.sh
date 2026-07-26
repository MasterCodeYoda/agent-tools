#!/usr/bin/env bash
# kevin-hermes container entry — ensure profile kevin + baked skills, then gateway.
set -euo pipefail

SKILLS_DIR="${KEVIN_SKILLS_DIR:-/opt/kevin/skills}"
PROFILE_SRC="${KEVIN_PROFILE_SRC:-/opt/kevin/profile}"
PLACEHOLDER="__HERMES_SKILLS_DIR__"

# Hermes data home in official image is /opt/data (volume).
export HERMES_HOME="${HERMES_HOME:-/opt/data}"
PROFILE_HOME="${HERMES_HOME}/profiles/kevin"
INSTALLED_CONFIG="${PROFILE_HOME}/config.yaml"

log() { echo "kevin-hermes: $*" >&2; }

if [[ ! -d "${SKILLS_DIR}" ]] || [[ -z "$(ls -A "${SKILLS_DIR}" 2>/dev/null || true)" ]]; then
  log "error: baked skills missing at ${SKILLS_DIR}"
  exit 1
fi

if [[ ! -f "${PROFILE_SRC}/distribution.yaml" ]]; then
  log "error: profile distribution missing at ${PROFILE_SRC}"
  exit 1
fi

# Locate hermes CLI (venv shim on PATH in official image).
HERMES_BIN="${HERMES_BIN:-hermes}"
if ! command -v "${HERMES_BIN}" >/dev/null 2>&1; then
  if [[ -x /opt/hermes/.venv/bin/hermes ]]; then
    HERMES_BIN=/opt/hermes/.venv/bin/hermes
  else
    log "error: hermes CLI not found"
    exit 1
  fi
fi

ensure_profile() {
  # Container s6 gateway slots require `profile create` (install alone is not enough).
  if ! "${HERMES_BIN}" profile show kevin >/dev/null 2>&1; then
    log "creating profile kevin (gateway registration)"
    "${HERMES_BIN}" profile create kevin -y 2>/dev/null \
      || "${HERMES_BIN}" profile create kevin \
      || true
  fi

  log "installing/updating profile kevin from ${PROFILE_SRC}"
  if ! "${HERMES_BIN}" profile install "${PROFILE_SRC}" --name kevin --force -y 2>/dev/null; then
    "${HERMES_BIN}" profile install "${PROFILE_SRC}" --name kevin --alias --force -y \
      || "${HERMES_BIN}" profile update kevin --force-config -y \
      || true
  fi

  if [[ ! -f "${INSTALLED_CONFIG}" ]]; then
    # Some layouts nest under HERMES_HOME differently — try common fallbacks
    for cand in \
      "${HERMES_HOME}/profiles/kevin/config.yaml" \
      "${HOME}/.hermes/profiles/kevin/config.yaml"
    do
      if [[ -f "${cand}" ]]; then
        INSTALLED_CONFIG="${cand}"
        PROFILE_HOME="$(dirname "${cand}")"
        break
      fi
    done
  fi

  if [[ -f "${INSTALLED_CONFIG}" ]]; then
    if grep -q "${PLACEHOLDER}" "${INSTALLED_CONFIG}" 2>/dev/null; then
      # portable in-place replace
      sed "s|${PLACEHOLDER}|${SKILLS_DIR}|g" "${INSTALLED_CONFIG}" > "${INSTALLED_CONFIG}.tmp"
      mv "${INSTALLED_CONFIG}.tmp" "${INSTALLED_CONFIG}"
      log "skills path → ${SKILLS_DIR}"
    elif ! grep -q "${SKILLS_DIR}" "${INSTALLED_CONFIG}" 2>/dev/null; then
      log "warning: config has neither placeholder nor ${SKILLS_DIR}; leave as-is"
    fi
  else
    log "warning: installed config not found; gateway may miss external_dirs"
  fi

  if [[ -f "${PROFILE_SRC}/.no-bundled-skills" && -d "${PROFILE_HOME}" ]]; then
    cp "${PROFILE_SRC}/.no-bundled-skills" "${PROFILE_HOME}/.no-bundled-skills" 2>/dev/null || true
  fi
}

ensure_profile

# Default: gateway under kevin. Allow override via args (e.g. doctor, version).
if [[ $# -eq 0 ]]; then
  set -- gateway run
fi

# Prefix with profile when invoking hermes subcommands
case "${1:-}" in
  gateway|doctor|profile|auth|cron|dashboard|chat|setup)
    log "exec: ${HERMES_BIN} -p kevin $*"
    exec "${HERMES_BIN}" -p kevin "$@"
    ;;
  -p)
    # already profile-qualified by caller
    log "exec: ${HERMES_BIN} $*"
    exec "${HERMES_BIN}" "$@"
    ;;
  *)
    # passthrough (bash, sleep, full path)
    log "exec: $*"
    exec "$@"
    ;;
esac
