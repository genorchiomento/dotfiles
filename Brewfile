# ============================================================
# Brewfile — todos os pacotes e apps
# Uso: brew bundle --file=Brewfile
# ============================================================

# Taps
tap "xcodesorg/made"

# ── CLI Tools ────────────────────────────────────────────
brew "git"
brew "bash"           # bash 5+ (necessário para SDKMAN)
brew "aria2"          # download paralelo (acelera xcodes)
brew "watchman"       # file watcher (Metro bundler Expo)
brew "mas"            # Mac App Store CLI
brew "trash"          # move para lixeira em vez de deletar

# ── Languages / Runtimes ────────────────────────────────
brew "node"           # Node.js (LTS via brew, ou use fnm/nvm)

# ── Browsers ────────────────────────────────────────────
cask "arc"              # browser moderno (dev-first)
cask "google-chrome"    # chrome
cask "firefox"          # firefox

# ── Comunicação ─────────────────────────────────────────
cask "slack"            # times
cask "discord"          # comunidades

# ── AI / Claude ─────────────────────────────────────────
cask "claude"           # Claude desktop app (Anthropic)

# ── Produtividade ────────────────────────────────────────
cask "raycast"          # launcher / spotlight turbinado
cask "notion"           # notas e docs

# ── Dev Tools ────────────────────────────────────────────
cask "visual-studio-code"  # editor
cask "intellij-idea"       # IntelliJ IDEA Ultimate
cask "cursor"              # VS Code + AI integrada (muito popular em 2025)
cask "warp"                # terminal moderno com AI
cask "postman"             # teste de APIs
cask "dbeaver-community"   # GUI databases free/open-source (Postgres, MySQL, SQLite, e mais)
cask "docker"              # Docker Desktop (containers)

# ── Mobile / React Native ────────────────────────────────
cask "android-studio"   # Android SDK + emulador + build tools

# ── Xcode ────────────────────────────────────────────────
# NÃO disponível via brew — instalar pelo App Store:
#   mas install 497799835
# Depois: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
#          sudo xcodebuild -license accept
