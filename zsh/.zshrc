# ============================================================
# .zshrc — gerado pelos dotfiles de ~/Projects/dotfiles
# ============================================================

DOTFILES="$HOME/Projects/dotfiles"

source "$DOTFILES/zsh/exports.zsh"
source "$DOTFILES/zsh/aliases.zsh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/$USER/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
