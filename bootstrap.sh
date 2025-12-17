#!/usr/bin/env bash

# =====================================================
# Strict mode (relaxed later if needed)
# =====================================================
set -euo pipefail

# =====================================================
# Detect CI modes EARLY
# =====================================================
IS_CI=false
IS_GITHUB_ACTIONS=false

if [[ "${CI:-}" == "true" ]]; then
  IS_CI=true
fi

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  IS_GITHUB_ACTIONS=true
fi

# =====================================================
# Local CI simulation safety
# =====================================================
# If CI=true but NOT running in GitHub Actions,
# relax strict mode to avoid Git Bash / local shell exits
if [[ "$IS_CI" == true && "$IS_GITHUB_ACTIONS" == false ]]; then
  set +e
fi

# =====================================================
# Quiet mode
# =====================================================
QUIET=false
if [[ "${1:-}" == "--quiet" ]]; then
  QUIET=true
fi

# =====================================================
# Constants
# =====================================================
CLUSTER_NAME="idan-app"

# =====================================================
# OS detection
# =====================================================
OS="$(uname -s)"
ARCH="$(uname -m)"

is_git_bash() {
  [[ "$OS" == MINGW* || "$OS" == MSYS* || "$OS" == CYGWIN* ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# =====================================================
# Colors
# =====================================================
enable_color=false
if [[ "$QUIET" == false && -z "${NO_COLOR:-}" ]]; then
  enable_color=true
fi

if [[ "$enable_color" == true ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

log()     { [[ "$QUIET" == false ]] && echo -e "$1"; }
info()    { log "${BLUE}[INFO]${NC} $1"; }
success() { log "${GREEN}[OK]${NC} $1"; }
warn()    { log "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# =====================================================
# Python helpers
# =====================================================
python_cmd() {
  if is_git_bash && command_exists py; then
    echo "py -3"
  elif command_exists python3; then
    echo "python3"
  else
    return 1
  fi
}

python_version() {
  local cmd
  cmd="$(python_cmd)" || return 1
  $cmd --version 2>&1 | head -n 1
}

# =====================================================
# Start
# =====================================================
info "Starting environment bootstrap"
info "Detected OS: $OS"
info "Detected ARCH: $ARCH"

if [[ "$IS_GITHUB_ACTIONS" == true ]]; then
  info "Running in GitHub Actions (strict CI)"
elif [[ "$IS_CI" == true ]]; then
  info "Running in local CI simulation"
fi

# =====================================================
# Python (optional)
# =====================================================
if python_cmd >/dev/null 2>&1; then
  success "Python available: $(python_version)"
else
  warn "Python not found (optional)"
fi

# =====================================================
# Docker (required only in GitHub Actions)
# =====================================================
if command_exists docker; then
  success "Docker available"
else
  if [[ "$IS_GITHUB_ACTIONS" == true ]]; then
    error "Docker is required in GitHub Actions"
    exit 1
  fi
  warn "Docker not found (local)"
fi

# =====================================================
# kubectl (required only in GitHub Actions)
# =====================================================
if command_exists kubectl; then
  success "kubectl available"
else
  if [[ "$IS_GITHUB_ACTIONS" == true ]]; then
    error "kubectl is required in GitHub Actions"
    exit 1
  fi
  warn "kubectl not found (local)"
fi

# =====================================================
# Helm (required only in GitHub Actions)
# =====================================================
if command_exists helm; then
  success "Helm available"
else
  if [[ "$IS_GITHUB_ACTIONS" == true ]]; then
    error "Helm is required in GitHub Actions"
    exit 1
  fi
  warn "Helm not found (local)"
fi

# =====================================================
# Optional tools
# =====================================================
command_exists kind && success "kind available" || warn "kind not found (optional)"
command_exists task && success "task available" || warn "task not found (optional)"

# =====================================================
# Summary
# =====================================================
log ""
info "Bootstrap summary"
log "--------------------------------------------"
success "Bootstrap completed successfully"
log "--------------------------------------------"

info "Next steps:"
info "  task docker-build"
info "  task deploy"

exit 0
