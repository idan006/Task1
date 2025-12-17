#!/usr/bin/env bash
set -euo pipefail

# =====================================================
# Quiet / CI mode
# =====================================================
QUIET=false
if [[ "${CI:-}" == "true" || "${1:-}" == "--quiet" ]]; then
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
# Colors (cross-OS safe)
# =====================================================
enable_color=false
if [[ "$QUIET" == false && -z "${NO_COLOR:-}" ]]; then
  if is_git_bash || [[ -n "${TERM:-}" && "${TERM}" != "dumb" ]] || [[ -n "${CI:-}" ]]; then
    enable_color=true
  fi
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
# Python helpers (Windows-safe)
# =====================================================
python_cmd() {
  if is_git_bash && command_exists py; then
    echo "py -3"
  elif command_exists python3; then
    echo "python3"
  else
    echo ""
  fi
}

python_version() {
  local cmd
  cmd="$(python_cmd)"
  [[ -n "$cmd" ]] || return 1
  eval "$cmd --version" 2>&1 | head -n 1
}

# =====================================================
# Start
# =====================================================
info "Starting prerequisites installation"
info "Detected OS: $OS"
info "Detected ARCH: $ARCH"

# =====================================================
# Python
# =====================================================
install_python() {
  if python_cmd >/dev/null; then
    success "Python already installed: $(python_version)"
    return
  fi

  warn "Python not found. Installing Python 3"

  if [[ "$OS" == "Linux" ]]; then
    sudo apt-get update -qq
    sudo apt-get install -y python3 python3-pip
  elif [[ "$OS" == "Darwin" ]]; then
    if ! command_exists brew; then
      warn "Homebrew not found. Installing Homebrew"
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install python
  elif is_git_bash && command_exists winget; then
    winget install -e --id Python.Python.3
  else
    error "Unsupported OS for Python installation"
    exit 1
  fi
}

# =====================================================
# Docker
# =====================================================
install_docker() {
  if command_exists docker; then
    success "Docker already installed: $(docker --version)"
    return
  fi

  warn "Docker not found"

  if [[ "$OS" == "Linux" ]]; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    warn "Log out and back in to use Docker without sudo"
  else
    error "Docker Desktop must be installed manually:"
    error "https://www.docker.com/products/docker-desktop/"
    exit 1
  fi
}

# =====================================================
# kubectl
# =====================================================
install_kubectl() {
  if command_exists kubectl; then
    success "kubectl already installed"
    return
  fi

  info "Installing kubectl"

  if [[ "$OS" == "Linux" ]]; then
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install kubectl /usr/local/bin/kubectl
    rm kubectl
  elif [[ "$OS" == "Darwin" ]]; then
    brew install kubectl
  elif is_git_bash && command_exists winget; then
    winget install -e --id Kubernetes.kubectl
  fi
}

# =====================================================
# Helm
# =====================================================
install_helm() {
  if command_exists helm; then
    success "Helm already installed"
    return
  fi

  info "Installing Helm"

  if [[ "$OS" == "Linux" ]]; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  elif [[ "$OS" == "Darwin" ]]; then
    brew install helm
  elif is_git_bash && command_exists winget; then
    winget install -e --id Helm.Helm
  fi
}

# =====================================================
# kind
# =====================================================
install_kind() {
  if command_exists kind; then
    success "kind already installed"
    return
  fi

  info "Installing kind"

  if [[ "$OS" == "Linux" ]]; then
    curl -Lo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x kind
    sudo mv kind /usr/local/bin/kind
  elif [[ "$OS" == "Darwin" ]]; then
    brew install kind
  elif is_git_bash && command_exists winget; then
    winget install -e --id Kubernetes.kind
  fi
}

# =====================================================
# task
# =====================================================
install_task() {
  if command_exists task; then
    success "task already installed"
    return
  fi

  info "Installing task"

  if [[ "$OS" == "Linux" ]]; then
    curl -fsSL https://taskfile.dev/install.sh | sudo bash
  elif [[ "$OS" == "Darwin" ]]; then
    brew install go-task
  elif is_git_bash && command_exists winget; then
    winget install -e --id Task.Task
  fi
}

# =====================================================
# Run installers
# =====================================================
install_python
install_docker
install_kubectl
install_helm
install_kind
install_task

# =====================================================
# Kubernetes bootstrap (LOCAL ONLY, not CI)
# =====================================================
if [[ "$QUIET" == false && -z "${CI:-}" ]]; then
  info "Kubernetes bootstrap (kind)"

  if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    info "Creating kind cluster: ${CLUSTER_NAME}"
    kind create cluster --name "${CLUSTER_NAME}"
  else
    success "kind cluster '${CLUSTER_NAME}' already exists"
  fi

  info "Verifying Kubernetes cluster"
  kubectl cluster-info
fi

# =====================================================
# Summary
# =====================================================
log ""
info "Installed tools summary"
log "--------------------------------------------"

if python_cmd >/dev/null; then
  success "$(printf '%-10s' "Python") : $(python_version)"
else
  error "$(printf '%-10s' "Python") : NOT INSTALLED"
fi

command_exists docker  && success "$(printf '%-10s' "Docker") : $(docker --version)"
command_exists helm    && success "$(printf '%-10s' "Helm")   : $(helm version | head -n 1)"
command_exists kubectl && success "$(printf '%-10s' "kubectl"): $(kubectl version --client 2>/dev/null | head -n 1)"
command_exists kind    && success "$(printf '%-10s' "kind")   : $(kind version)"
command_exists task    && success "$(printf '%-10s' "task")   : $(task --version)"

log "--------------------------------------------"
success "Prerequisites installation completed"

# =====================================================
# Final Kubernetes status
# =====================================================
if [[ "$QUIET" == false && -z "${CI:-}" ]]; then
  log ""
  info "Kubernetes status"
  log "--------------------------------------------"

  if kubectl get nodes >/dev/null 2>&1; then
    success "Kubernetes cluster '${CLUSTER_NAME}' is reachable"
    kubectl get nodes
  else
    error "Kubernetes cluster '${CLUSTER_NAME}' is NOT reachable"
  fi

  log "--------------------------------------------"
fi

if is_git_bash; then
  warn "Windows notice: restart Git Bash if PATH changed during this run"
fi

info "Next steps:"
info "  task docker-build"
info "  task kind-deploy"
