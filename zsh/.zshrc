# ============================================================
# .zshrc — gerado pelos dotfiles de ~/Projects/dotfiles
# ============================================================

DOTFILES="$HOME/Projects/dotfiles"

source "$DOTFILES/zsh/exports.zsh"
source "$DOTFILES/zsh/aliases.zsh"

# === Completions ===
# Docker CLI — só entra no fpath se o Docker Desktop estiver instalado
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
