# ============================================================
# exports.zsh — variáveis de ambiente
# ============================================================

# PATH base
export PATH="$HOME/.local/bin:$PATH"

# VS Code CLI
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# Android SDK (React Native / Expo local builds)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"

# Java via SDKMAN (Java 17 — requerido para Android builds)
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
