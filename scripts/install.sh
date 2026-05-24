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
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log()    { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }
ok()     { echo -e "  ${GREEN}✅ $1${NC}"; }
warn()   { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
fail()   { echo -e "  ${RED}❌ $1${NC}"; }
divider(){ echo -e "${BOLD}────────────────────────────────────────${NC}"; }

clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        dotfiles — setup automático       ║${NC}"
echo -e "${BOLD}║        macOS (Apple Silicon)             ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Homebrew ───────────────────────────────────────────
log "Homebrew"
if ! command -v brew &>/dev/null; then
  echo "  Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew instalado"
else
  ok "Homebrew: $(brew --version | head -1)"
fi

# ── 2. Brewfile (apps + cli tools) ───────────────────────
log "Pacotes e Apps (Brewfile)"
echo "  Isso pode demorar — instalando browsers, IDEs, dev tools..."
brew bundle --file="$DOTFILES/Brewfile" --no-lock
ok "Brewfile concluído"

# ── 3. SDKMAN ────────────────────────────────────────────
log "SDKMAN"
if [[ ! -d "$HOME/.sdkman" ]]; then
  echo "  Instalando SDKMAN..."
  export SDKMAN_DIR="$HOME/.sdkman"
  curl -s "https://get.sdkman.io" | bash
  ok "SDKMAN instalado"
else
  ok "SDKMAN já instalado"
fi
source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── 4. Java 17 (Android builds) ──────────────────────────
log "Java 17 (Temurin)"
if ! sdk list java 2>/dev/null | grep -q "17.0.11-tem.*installed"; then
  echo "  Instalando Java 17..."
  sdk install java 17.0.11-tem
  ok "Java 17 instalado"
else
  ok "Java 17 já instalado"
fi
sdk default java 17.0.11-tem
ok "Java default: $(java -version 2>&1 | head -1)"

# ── 5. EAS CLI ───────────────────────────────────────────
log "EAS CLI (Expo)"
npm install -g eas-cli 2>/dev/null
ok "EAS CLI: $(eas --version 2>/dev/null | head -1)"

# ── 6. Symlink .zshrc ────────────────────────────────────
log "Configurando ~/.zshrc"
ZSHRC_SOURCE="$DOTFILES/zsh/.zshrc"
ZSHRC_TARGET="$HOME/.zshrc"

if [[ -f "$ZSHRC_TARGET" && ! -L "$ZSHRC_TARGET" ]]; then
  BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
  warn "Backup salvo em $BACKUP"
  cp "$ZSHRC_TARGET" "$BACKUP"
fi

ln -sf "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
ok "~/.zshrc → symlink para dotfiles/zsh/.zshrc"

# ── 7. Xcode ─────────────────────────────────────────────
log "Xcode"
if [[ -d "/Applications/Xcode.app" ]]; then
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null || true
  sudo xcodebuild -license accept 2>/dev/null || true
  ok "Xcode: $(xcodebuild -version 2>/dev/null | head -1)"
else
  warn "Xcode não instalado — passos manuais:"
  warn "  1. mas install 497799835"
  warn "  2. sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  warn "  3. sudo xcodebuild -license accept"
fi

# ── 8. Android SDK ───────────────────────────────────────
log "Android Studio"
if [[ -d "/Applications/Android Studio.app" ]]; then
  ok "Android Studio instalado"
  warn "Ação necessária: abra o Android Studio e instale Android SDK API 34"
else
  warn "Android Studio não encontrado (deveria ter sido instalado pelo Brewfile)"
fi

# ── 9. Resumo final ──────────────────────────────────────
divider
echo ""
echo -e "${BOLD}${GREEN}  Setup concluído! 🎉${NC}"
echo ""
echo -e "${BOLD}  Próximos passos:${NC}"
echo "  1.  source ~/.zshrc"
echo "  2.  Abra Android Studio → SDK Manager → instale API 34"
echo "  3.  eas login               (autenticar no Expo)"
echo "  4.  Abra Xcode → aceite termos (se necessário)"
echo ""
echo -e "${BOLD}  Criar primeiro app Expo:${NC}"
echo "  cd ~/Projects"
echo "  expo-new-stack              (seletor interativo)"
echo "  # ou"
echo "  expo-new-pro <NomeApp>      (template produção completo)"
echo ""
divider
