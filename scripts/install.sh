#!/usr/bin/env bash
# ============================================================
# install.sh — bootstrap completo do ambiente de desenvolvimento
# Uso: bash ~/Projects/dotfiles/scripts/install.sh
# ============================================================

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BOLD}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     dotfiles — setup automático      ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""

# ── 1. Homebrew ───────────────────────────────────────────
log "Verificando Homebrew..."
if ! command -v brew &>/dev/null; then
  log "Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew instalado"
else
  ok "Homebrew já instalado: $(brew --version | head -1)"
fi

# ── 2. Pacotes via Brewfile ───────────────────────────────
log "Instalando pacotes via Brewfile..."
brew bundle --file="$DOTFILES/Brewfile" --no-lock
ok "Brewfile concluído"

# ── 3. SDKMAN ────────────────────────────────────────────
log "Verificando SDKMAN..."
if [[ ! -d "$HOME/.sdkman" ]]; then
  log "Instalando SDKMAN..."
  export SDKMAN_DIR="$HOME/.sdkman"
  curl -s "https://get.sdkman.io" | bash
  ok "SDKMAN instalado"
else
  ok "SDKMAN já instalado"
fi

# Carregar SDKMAN
source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── 4. Java 17 ───────────────────────────────────────────
log "Verificando Java 17..."
if ! sdk list java 2>/dev/null | grep -q "17.0.11-tem.*installed"; then
  log "Instalando Java 17 (Temurin)..."
  sdk install java 17.0.11-tem
  ok "Java 17 instalado"
else
  ok "Java 17 já instalado"
fi
sdk default java 17.0.11-tem

# ── 5. Node / npm global packages ────────────────────────
log "Verificando Node..."
if ! command -v node &>/dev/null; then
  fail "Node não encontrado — instale via brew (já no Brewfile) e re-execute"
  exit 1
fi
ok "Node: $(node --version)"

log "Instalando EAS CLI global..."
npm install -g eas-cli 2>/dev/null
ok "EAS CLI: $(eas --version 2>/dev/null || echo 'instalado')"

# ── 6. Symlink .zshrc ────────────────────────────────────
log "Configurando .zshrc..."
ZSHRC_SOURCE="$DOTFILES/zsh/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

if [[ -f "$ZSHRC_TARGET" && ! -L "$ZSHRC_TARGET" ]]; then
  BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  warn "Backup do .zshrc existente → $BACKUP"
  cp "$ZSHRC_TARGET" "$BACKUP"
fi

ln -sf "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
ok ".zshrc → symlink para $ZSHRC_SOURCE"

# ── 7. Xcode ─────────────────────────────────────────────
log "Verificando Xcode..."
if [[ -d "/Applications/Xcode.app" ]]; then
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -license accept 2>/dev/null || true
  ok "Xcode configurado: $(xcodebuild -version 2>/dev/null | head -1)"
else
  warn "Xcode não encontrado — instale via App Store (ID: 497799835)"
  warn "Depois rode: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  warn "             sudo xcodebuild -license accept"
fi

# ── 8. Android Studio ────────────────────────────────────
log "Verificando Android Studio..."
if [[ -d "/Applications/Android Studio.app" ]]; then
  ok "Android Studio instalado"
  warn "Abra o Android Studio e instale Android SDK API 34 via SDK Manager"
else
  warn "Android Studio não encontrado — será instalado pelo Brewfile"
fi

# ── 9. Resumo ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${BOLD}║           Setup concluído!           ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo "  Rode: source ~/.zshrc"
echo ""
echo "  Próximos passos manuais:"
echo "  1. Abra Android Studio → instale Android SDK API 34"
echo "  2. Instale Xcode via App Store (se ainda não feito)"
echo "  3. eas login (autenticar no Expo)"
echo "  4. cd ~/Projects && expo-new-stack (criar primeiro app)"
echo ""
