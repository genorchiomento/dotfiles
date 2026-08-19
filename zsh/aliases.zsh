# ============================================================
# aliases.zsh — todos os aliases do shell
# Fonte: ~/Projects/dotfiles/zsh/aliases.zsh
# ============================================================

# === Editar configs rapidamente ===
alias codebash="code ~/.zshrc"
alias codegit="code ~/.gitconfig"
alias reload="source ~/.zshrc"
alias dotfiles="cd ~/Projects/dotfiles"

# === Git ===
alias gst="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit -m"
alias gco="git checkout"
alias gb="git branch"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --oneline --graph --decorate --all"
alias gd="git diff"

# === Navegação ===
alias ll="ls -lah"
alias la="ls -A"
alias ..="cd .."
alias ...="cd ../.."
alias cd-="cd $HOME/Projects"

# === IP ===
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# === Arquivos ===
alias delete="trash"

# === Claude Code ===
alias clauded="claude --dangerously-skip-permissions"

# === Expo — Dev Server ===
alias es="npx expo start"
alias esd="npx expo start --dev-client"    # preferir sobre Expo Go
alias est="npx expo start --tunnel"        # dispositivos físicos em redes restritas
alias esi="npx expo start --ios"
alias esa="npx expo start --android"

# === Expo — Build & Run local ===
alias eri="npx expo run:ios"
alias era="npx expo run:android"
alias epb="npx expo prebuild"
alias epbc="npx expo prebuild --clean"

# === Expo — Pacotes (SEMPRE usar no lugar de npm install) ===
alias ei="npx expo install"

# === Expo — Utilitários ===
alias elint="npx expo lint"
alias econfig="npx expo config"
alias expo-reset="npx expo start --clear"

# === Expo — Combos ===
alias expo-ios="npx expo prebuild --clean && npx expo run:ios"
alias expo-android="npx expo prebuild --clean && npx expo run:android"

# === Expo — Criar projetos ===
alias expo-new="npx create-expo-app@latest"
alias expo-new-pro="npx create-obytes-app"          # Router+NativeWind+TanStack+Zustand
alias expo-new-stack="npx create-expo-stack@latest"  # seletor interativo

# === EAS Build ===
alias easd="eas build --profile development"
alias easdi="eas build --profile development --platform ios"
alias easda="eas build --profile development --platform android"
alias easp="eas build --profile preview"
alias easpi="eas build --profile preview --platform ios"
alias easpa="eas build --profile preview --platform android"
alias easprod="eas build --profile production"
alias easprodi="eas build --profile production --platform ios"
alias easproda="eas build --profile production --platform android"

# === EAS Update / Submit ===
alias easu="eas update"
alias easum="eas update --branch main"
alias eassubi="eas submit --platform ios"
alias eassuba="eas submit --platform android"
alias easinfo="eas project:info"

# === Scripts pessoais ===
# Só definidos se o script existir — evita alias quebrado em máquina nova
[[ -f "$HOME/Projects/scripts/hotmart-downloader/server.py" ]] && \
  alias hotmart="python3 $HOME/Projects/scripts/hotmart-downloader/server.py"
