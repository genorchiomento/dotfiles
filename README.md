# dotfiles

Setup automático do ambiente de desenvolvimento — macOS (Apple Silicon).

## O que instala

| Ferramenta | Como |
|---|---|
| Homebrew | automático se ausente |
| git, bash, aria2, watchman, mas | Brewfile |
| Android Studio | Brewfile (cask) |
| IntelliJ IDEA Ultimate | Brewfile (cask) |
| VS Code | Brewfile (cask) |
| SDKMAN | automático |
| Java 17 (Temurin) | SDKMAN |
| EAS CLI | npm global |
| Xcode | App Store — manual (8GB) |

## Uso

### Máquina nova

```bash
# 1. Clonar
git clone https://github.com/SEU_USUARIO/dotfiles.git ~/Projects/dotfiles

# 2. Executar bootstrap
bash ~/Projects/dotfiles/scripts/install.sh

# 3. Recarregar shell
source ~/.zshrc
```

### Xcode (único passo manual)

```bash
# Instalar via App Store
mas install 497799835

# Configurar após instalação
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### Android SDK (pós Android Studio)

Abra Android Studio → SDK Manager → instale **Android API 34**.

## Estrutura

```
dotfiles/
├── Brewfile              # todos os pacotes brew/cask
├── scripts/
│   └── install.sh        # bootstrap principal
├── zsh/
│   ├── .zshrc            # entry point (symlinked para ~/.zshrc)
│   ├── exports.zsh       # variáveis de ambiente (PATH, ANDROID_HOME, etc.)
│   └── aliases.zsh       # todos os aliases
└── README.md
```

## Aliases Expo / EAS

| Alias | Comando |
|---|---|
| `es` | `npx expo start` |
| `esd` | `npx expo start --dev-client` |
| `est` | `npx expo start --tunnel` |
| `eri` / `era` | `expo run:ios` / `run:android` |
| `epb` / `epbc` | `expo prebuild` / `--clean` |
| `ei` | `npx expo install` |
| `expo-new` | create-expo-app (default) |
| `expo-new-pro` | obytes template (produção) |
| `expo-new-stack` | create-expo-stack (interativo) |
| `easd/p/prod` | EAS build por perfil |
| `easu` / `easum` | EAS OTA update |
| `eassubi/a` | EAS submit iOS/Android |

## Atualizar

```bash
cd ~/Projects/dotfiles
git pull
source ~/.zshrc
```
