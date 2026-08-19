# dotfiles

Setup automático do ambiente de desenvolvimento macOS (Apple Silicon).  
Um comando instala apps, CLI tools, aliases e variáveis de ambiente — e você escolhe o que entra.

---

## Instalação rápida

```bash
# 1. Clonar
git clone https://github.com/genorchiomento/dotfiles.git ~/Projects/dotfiles

# 2. Executar bootstrap (menu interativo)
bash ~/Projects/dotfiles/scripts/install.sh

# 3. Recarregar shell
source ~/.zshrc
```

> **Tempo estimado:** 15–30 min instalando tudo (~1.5GB de apps). Selecionando só o que precisa, bem menos.

### Escolhendo o que instalar

O script abre uma lista navegável por setas:

```
    [x] ▸ CLI Tools                 6/6
    [x] ▸ Languages / Runtimes      1/1
    [ ] ▸ Browsers                  0/3
  ❯ [~] ▾ Dev Tools                 5/7
        [x] visual-studio-code      editor
        [ ] intellij-idea           IntelliJ IDEA Ultimate
        [x] cursor                  VS Code + AI integrada (muito popul…
      ▼ mais abaixo

  ↑↓ mover   → abrir   ← fechar   espaço marcar
  a tudo    n nada    ENTER instalar   q sair
```

| Tecla | Ação |
|---|---|
| `↑` `↓` | mover o cursor (`k`/`j` também) |
| `→` | abrir a categoria; se já aberta, desce pro primeiro app |
| `←` | fechar a categoria (de dentro dela, volta pro topo) |
| `espaço` | marcar/desmarcar — na categoria vale pra todos os apps dela |
| `a` / `n` | marcar tudo / desmarcar tudo |
| `ENTER` | instalar o que estiver marcado |
| `q` | sair sem instalar |

`[~]` = seleção parcial. `▸`/`▾` = categoria fechada/aberta. A lista rola sozinha se não couber na tela.

### Modo não-interativo

```bash
bash scripts/install.sh --all                  # tudo, sem perguntar
bash scripts/install.sh --only=dev,browsers    # só essas categorias (nome ou número)
bash scripts/install.sh --dry-run              # mostra o plano, não instala
bash scripts/install.sh --list                 # lista as categorias
bash scripts/install.sh --help
```

### Sobre a senha do macOS

Se a seleção incluir apps `cask` ou o Xcode, o script pede sua senha **uma vez, logo no começo**, explicando por quê:

```
▶ Permissão de administrador
  Alguns apps (Docker e outros) criam symlinks em /usr/local/bin,
  que pertence ao root. O Xcode também precisa.
  Digite sua senha do macOS uma vez agora — assim a instalação não
  para no meio pedindo senha sem contexto.
```

O motivo: em Apple Silicon o Homebrew mora em `/opt/homebrew` (teu), mas `/usr/local` continua `root:wheel` — e casks com artefato `binary` (Docker, por exemplo) criam symlinks lá. Sem pedir antes, o `sudo` dispararia no meio da instalação como um `Password:` pelado, sem dizer quem pediu.

Se você recusar, o script **não aborta**: segue instalando o que não precisa de root, e o que precisar entra no resumo como falha. Selecionando só apps que não usam `cask`, ele nem pergunta.

### Se algum app falhar

O script **não para**. Ele instala e configura tudo que der certo, e mostra as falhas juntas no final:

```
  RESUMO

    ✅ instalados:   14
    ⏭  já presentes: 3
    ❌ falhas:      1

  Falhas — o resto foi configurado normalmente
    ❌ docker
       brew install --cask falhou: Error: Cask 'docker' is unavailable.

    Log completo: ~/.dotfiles-install-20260819_095441.log
```

Pra tentar de novo, rode o script e marque só os itens que falharam — ele é idempotente e pula o que já está instalado.

> Adicionou um app novo ao `Brewfile`? Ele aparece no menu sozinho — o catálogo é lido do próprio Brewfile.

---

## O que é instalado

### Browsers
| App | Cask |
|---|---|
| Arc | `arc` |
| Google Chrome | `google-chrome` |
| Firefox | `firefox` |

### Comunicação
| App | Cask |
|---|---|
| Slack | `slack` |
| Discord | `discord` |

### AI
| App | Cask |
|---|---|
| Claude (desktop) | `claude` |

### Produtividade
| App | Cask |
|---|---|
| Raycast | `raycast` |
| Notion | `notion` |

### Dev Tools
| App | Cask |
|---|---|
| VS Code | `visual-studio-code` |
| IntelliJ IDEA Ultimate | `intellij-idea` |
| Warp Terminal | `warp` |
| Postman | `postman` |
| TablePlus | `tableplus` |

### Mobile / React Native
| App | Cask |
|---|---|
| Android Studio | `android-studio` |

### CLI Tools (brew)
| Ferramenta | Para quê |
|---|---|
| `git` | controle de versão |
| `bash` | bash 5+ (SDKMAN precisa) |
| `aria2` | download paralelo |
| `watchman` | file watcher (Metro bundler) |
| `mas` | Mac App Store CLI |
| `trash` | deletar com segurança |
| `node` | Node.js runtime |

### Runtimes (automático via script)
| Ferramenta | Versão | Via |
|---|---|---|
| SDKMAN | latest | curl installer |
| Java | 17.0.11 (Temurin) | SDKMAN |
| EAS CLI | latest | npm global |

---

## Xcode (único passo manual)

Xcode não está disponível via Homebrew. Instale pelo App Store:

```bash
# Instalar via mas CLI (já instalado pelo Brewfile)
mas install 497799835

# Após instalação, configurar:
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

> **Alternativa:** abra o App Store → pesquise "Xcode" → instale (~8GB)

---

## Android SDK (pós Android Studio)

1. Abra **Android Studio**
2. `Settings → SDK Manager`
3. Instale **Android SDK API 34** (Android 14)
4. Instale **Android SDK Build-Tools** e **Android Emulator**

O `ANDROID_HOME` já está configurado automaticamente em `zsh/exports.zsh`.

---

## Estrutura dos dotfiles

```
dotfiles/
├── Brewfile                  # todos os pacotes brew/cask
├── scripts/
│   └── install.sh            # bootstrap (menu de seleção + resumo de erros)
├── zsh/
│   ├── .zshrc                # entry point → symlinked para ~/.zshrc
│   ├── exports.zsh           # variáveis de ambiente (PATH, ANDROID_HOME, JAVA_HOME)
│   └── aliases.zsh           # todos os aliases organizados por categoria
└── README.md
```

`~/.zshrc` é um **symlink** para `dotfiles/zsh/.zshrc`.  
Edite sempre os arquivos dentro de `dotfiles/` — nunca direto em `~/.zshrc`.

---

## Aliases — referência completa

### Shell / Navegação
| Alias | Comando |
|---|---|
| `reload` | `source ~/.zshrc` |
| `codebash` | abre ~/.zshrc no VS Code |
| `codegit` | abre ~/.gitconfig no VS Code |
| `dotfiles` | `cd ~/Projects/dotfiles` |
| `ll` | `ls -lah` |
| `la` | `ls -A` |
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `cd-` | `cd ~/Projects` |

### Git
| Alias | Comando |
|---|---|
| `gst` | `git status` |
| `ga` | `git add` |
| `gaa` | `git add .` |
| `gc "msg"` | `git commit -m "msg"` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gl` | `git log --oneline --graph --decorate --all` |
| `gd` | `git diff` |

### Expo — Dev Server
| Alias | Comando | Quando usar |
|---|---|---|
| `es` | `npx expo start` | dev rápido com Expo Go |
| `esd` | `npx expo start --dev-client` | **preferido** — dev client com módulos nativos |
| `est` | `npx expo start --tunnel` | dispositivo físico em rede restrita |
| `esi` | `npx expo start --ios` | abre direto no simulador iOS |
| `esa` | `npx expo start --android` | abre direto no emulador Android |
| `expo-reset` | `npx expo start --clear` | limpa cache Metro |

### Expo — Build & Run local
| Alias | Comando |
|---|---|
| `eri` | `npx expo run:ios` |
| `era` | `npx expo run:android` |
| `epb` | `npx expo prebuild` |
| `epbc` | `npx expo prebuild --clean` |
| `expo-ios` | prebuild --clean + run:ios |
| `expo-android` | prebuild --clean + run:android |

### Expo — Utilitários
| Alias | Comando |
|---|---|
| `ei` | `npx expo install` ← **sempre instalar pacotes assim** |
| `elint` | `npx expo lint` |
| `econfig` | `npx expo config` |

### Expo — Criar projetos
| Alias | Template | Stack |
|---|---|---|
| `expo-new` | create-expo-app | Expo Router + TypeScript (oficial) |
| `expo-new-pro` | create-obytes-app | Router + NativeWind + TanStack Query + Zustand |
| `expo-new-stack` | create-expo-stack | seletor interativo de stack |

### EAS Build
| Alias | Perfil | Plataforma |
|---|---|---|
| `easd` | development | todas |
| `easdi` | development | iOS |
| `easda` | development | Android |
| `easp` | preview | todas |
| `easpi` | preview | iOS |
| `easpa` | preview | Android |
| `easprod` | production | todas |
| `easprodi` | production | iOS |
| `easproda` | production | Android |

### EAS Update / Submit
| Alias | Comando |
|---|---|
| `easu` | `eas update` |
| `easum` | `eas update --branch main` |
| `eassubi` | `eas submit --platform ios` |
| `eassuba` | `eas submit --platform android` |
| `easinfo` | `eas project:info` |

### Network / IP
| Alias | Descrição |
|---|---|
| `ip` | IP público |
| `localip` | IP local (en0) |
| `ips` | todos os IPs |
| `ifactive` | interfaces ativas |

---

## Variáveis de ambiente configuradas

```bash
ANDROID_HOME="$HOME/Library/Android/sdk"
JAVA_HOME="$HOME/.sdkman/candidates/java/current"  # Java 17
PATH includes: Android tools, platform-tools, emulator, VS Code CLI, ~/.local/bin
```

---

## Atualizar dotfiles

```bash
cd ~/Projects/dotfiles
git pull
source ~/.zshrc
```

Para novos pacotes, edite `Brewfile` e rode:

```bash
brew bundle --file=~/Projects/dotfiles/Brewfile
```

---

## Stack Expo recomendada (2025)

```
Routing:      Expo Router (file-based, universal iOS+Android+Web)
Styling:      NativeWind v4 (Tailwind CSS)
Server state: TanStack Query
Local state:  Zustand + MMKV
Forms:        TanStack Form + Zod
Lists:        FlashList (Shopify) — substitui FlatList
Images:       expo-image
Animations:   Reanimated v4
Auth:         Clerk
E2E tests:    Maestro
Monitoring:   Sentry
```

Criar projeto com essa stack completa:

```bash
cd ~/Projects
expo-new-pro NomeDoApp
```
