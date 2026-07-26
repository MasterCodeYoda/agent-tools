#!/usr/bin/env bash
# Apply the Kevin Hermes profile distribution from this repo.
# Primary mechanism: hermes profile install / update (never custom-merges secrets).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: apply-kevin-profile.sh [options]

Install or re-install Hermes profile "kevin" from hermes/profile/ in this repo.

Installs from the stable repo path so `hermes profile update kevin` can re-pull.
After install/update, substitutes __HERMES_SKILLS_DIR__ in the *installed*
config.yaml with the absolute managed skills path.

Options:
  --force           Overwrite an existing kevin profile (Hermes --force; user data preserved)
  --force-config    Also re-apply distribution config (hermes profile update --force-config)
  --no-alias        Do not create Hermes thin kevin alias (prefer product kevin CLI on PATH)
  --skip-skills-check
                    Install even if Kevin skills root is missing (not recommended)
  -y, --yes         Non-interactive install confirmation
  -h, --help        Show this help

Environment:
  KEVIN_SKILLS_ROOT   Kevin skills root (preferred; default: $HOME/.kevin/skills)
  HERMES_SKILLS_DIR   Override skills path (legacy alias for the same value)

Product path (ADR-004): ~/.kevin/skills — prefer: kevin setup

Examples:
  ./scripts/apply-kevin-profile.sh
  ./scripts/apply-kevin-profile.sh --force --no-alias -y
  ./scripts/apply-kevin-profile.sh --force --force-config -y
EOF
}

FORCE=0
FORCE_CONFIG=0
SKIP_SKILLS=0
YES=0
NO_ALIAS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --force-config) FORCE_CONFIG=1; shift ;;
    --no-alias) NO_ALIAS=1; shift ;;
    --skip-skills-check) SKIP_SKILLS=1; shift ;;
    -y|--yes) YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This file lives at hermes/scripts/; profile is hermes/profile/; repo root is ../..
HERMES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC="${HERMES_DIR}/profile"
# Product default: Kevin skills root (ADR-004). HERMES_SKILLS_DIR remains an override.
SKILLS_DIR="${HERMES_SKILLS_DIR:-${KEVIN_SKILLS_ROOT:-${HOME}/.kevin/skills}}"
PLACEHOLDER="__HERMES_SKILLS_DIR__"
PROFILE_HOME="${HOME}/.hermes/profiles/kevin"
INSTALLED_CONFIG="${PROFILE_HOME}/config.yaml"

if [[ ! -f "${SRC}/distribution.yaml" ]]; then
  echo "error: missing distribution at ${SRC}/distribution.yaml" >&2
  exit 1
fi

if ! command -v hermes >/dev/null 2>&1; then
  echo "error: hermes CLI not found on PATH" >&2
  exit 1
fi

if [[ ! -d "${SKILLS_DIR}" ]]; then
  msg="error: Kevin skills root missing: ${SKILLS_DIR}
  Product path: kevin setup   (or tools/install-kevin-skills.sh --from-url)
  Maintainer:   tools/install-kevin-skills.sh --from-file dist/kevin-skills/kevin-skills.tar.gz
  Override with KEVIN_SKILLS_ROOT=... / HERMES_SKILLS_DIR=... or pass --skip-skills-check."
  if [[ "${SKIP_SKILLS}" -eq 1 ]]; then
    echo "warning: ${msg}" >&2
  else
    echo "${msg}" >&2
    exit 1
  fi
fi

profile_exists() {
  # Prefer show (stable) over parsing the list table.
  hermes profile show kevin >/dev/null 2>&1
}

substitute_skills_path() {
  if [[ ! -f "${INSTALLED_CONFIG}" ]]; then
    echo "error: expected installed config at ${INSTALLED_CONFIG}" >&2
    exit 1
  fi
  if grep -q "${PLACEHOLDER}" "${INSTALLED_CONFIG}"; then
    sed -i.bak "s|${PLACEHOLDER}|${SKILLS_DIR}|g" "${INSTALLED_CONFIG}"
    rm -f "${INSTALLED_CONFIG}.bak"
    echo "→ substituted skills path in installed config → ${SKILLS_DIR}"
  else
    # Already absolute or operator-edited; ensure our skills dir is present if still placeholder-free
    if ! grep -q "${SKILLS_DIR}" "${INSTALLED_CONFIG}"; then
      echo "warning: ${INSTALLED_CONFIG} has no placeholder and no ${SKILLS_DIR}; leave as-is" >&2
    else
      echo "→ skills path already set in installed config"
    fi
  fi
}

if profile_exists && [[ "${FORCE}" -eq 0 && "${FORCE_CONFIG}" -eq 0 ]]; then
  echo "Profile 'kevin' already exists."
  echo "  Re-apply distribution files:  $0 --force -y"
  echo "  Refresh config from dist:     $0 --force-config -y"
  echo "  (Secrets under ${PROFILE_HOME} are never deleted by this script.)"
  exit 0
fi

if profile_exists && [[ "${FORCE_CONFIG}" -eq 1 && "${FORCE}" -eq 0 ]]; then
  UPD=(profile update kevin --force-config)
  if [[ "${YES}" -eq 1 ]]; then
    UPD+=(-y)
  fi
  echo "→ hermes ${UPD[*]}"
  if ! hermes "${UPD[@]}"; then
    echo "warning: hermes profile update failed (source may be a prior staging path)." >&2
    echo "  Re-run with --force to reinstall from ${SRC}" >&2
    exit 1
  fi
  substitute_skills_path
else
  # Install from stable repo path so distribution source is this tree (not a temp dir).
  INSTALL_ARGS=(profile install "${SRC}" --name kevin)
  if [[ "${NO_ALIAS}" -eq 0 ]]; then
    INSTALL_ARGS+=(--alias)
  fi
  if [[ "${FORCE}" -eq 1 ]] || profile_exists; then
    INSTALL_ARGS+=(--force)
  fi
  if [[ "${YES}" -eq 1 ]]; then
    INSTALL_ARGS+=(-y)
  fi
  echo "→ hermes ${INSTALL_ARGS[*]}"
  hermes "${INSTALL_ARGS[@]}"
  substitute_skills_path
fi

# Ensure blank-bundled marker is present on the installed profile
if [[ -f "${SRC}/.no-bundled-skills" ]]; then
  cp "${SRC}/.no-bundled-skills" "${PROFILE_HOME}/.no-bundled-skills"
fi

echo
echo "Kevin profile apply complete."
echo "  Launch: kevin   (product CLI) or hermes -p kevin"
echo "  Profile: ${PROFILE_HOME}"
echo "  Source:  ${SRC}"
echo "  Secrets: fill ${PROFILE_HOME}/.env (from .env.template / .env.EXAMPLE) or use auth.json"
echo "  Process skills (product): ${SKILLS_DIR}  (kevin setup / install-kevin-skills.sh)"
echo "  Legacy dogfood used hermes -p factory — prefer kevin; do not auto-delete factory."
