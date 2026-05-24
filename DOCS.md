# Documentação técnica dos dotfiles

Guia completo de manutenção — o que cada arquivo faz, cada linha, cada comando.

---

## Estrutura de arquivos

```
dotfiles/
├── Brewfile              → lista de apps e ferramentas para instalar via brew
├── DOCS.md               → este arquivo (documentação de manutenção)
├── README.md             → visão geral e referência rápida
├── scripts/
│   └── install.sh        → script de bootstrap (roda tudo do zero)
└── zsh/
    ├── .zshrc            → entry point do shell (symlinked para ~/.zshrc)
    ├── exports.zsh       → variáveis de ambiente (PATH, ANDROID_HOME, etc.)
    └── aliases.zsh       → atalhos de terminal organizados por categoria
```

**Como o shell funciona:**  
Quando você abre um terminal, o macOS lê `~/.zshrc`.  
Esse arquivo é um **symlink** (atalho) que aponta para `dotfiles/zsh/.zshrc`.  
O `.zshrc` por sua vez carrega `exports.zsh` e `aliases.zsh`.  
Resultado: editar qualquer arquivo dentro de `dotfiles/zsh/` afeta o terminal imediatamente após `reload`.

---

## `zsh/.zshrc` — entry point do shell

```bash
DOTFILES="$HOME/Projects/dotfiles"
```
Define a variável `DOTFILES` com o caminho absoluto do repositório.  
Usada nas linhas seguintes para não hardcodar caminhos.  
Se você mover o repositório para outro lugar, só precisa mudar aqui.

```bash
source "$DOTFILES/zsh/exports.zsh"
source "$DOTFILES/zsh/aliases.zsh"
```
`source` executa o arquivo no contexto do shell atual (diferente de rodar um script filho).  
Carrega as variáveis de ambiente e os aliases na sessão.

```bash
export SDKMAN_DIR="/Users/$USER/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```
**Precisa ficar no final do arquivo** — requisito do SDKMAN.  
`[[ -s "..." ]]` verifica se o arquivo existe E não está vazio antes de carregar.  
`$USER` é o nome do usuário atual (mais portável que hardcodar o nome).  
SDKMAN injeta o comando `sdk` e configura o `JAVA_HOME` dinamicamente.

---

## `zsh/exports.zsh` — variáveis de ambiente

### PATH base
```bash
export PATH="$HOME/.local/bin:$PATH"
```
Adiciona `~/.local/bin` ao início do PATH.  
Ferramentas instaladas manualmente (sem brew) ficam aqui.  
O `:$PATH` no final **preserva** todos os caminhos já existentes — nunca sobrescreve.

### VS Code CLI
```bash
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
```
Habilita o comando `code` no terminal.  
Sem isso, `code arquivo.ts` não funciona fora do VS Code.  
Exemplo: `code .` abre o diretório atual no VS Code.

### Android SDK
```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
```
Define onde o Android SDK está instalado.  
O Android Studio instala o SDK em `~/Library/Android/sdk` por padrão no macOS.  
Ferramentas como `expo run:android` e `adb` usam essa variável para encontrar o SDK.

```bash
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$PATH"
```
Adiciona 4 diretórios do Android SDK ao PATH:
- `emulator` → comando `emulator` para iniciar emuladores Android
- `platform-tools` → comando `adb` (Android Debug Bridge — conectar dispositivos físicos)
- `tools` → ferramentas legadas do SDK
- `tools/bin` → `avdmanager` (gerenciar emuladores), `sdkmanager` (gerenciar SDKs)

### Java
```bash
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
```
Aponta para o Java ativo no SDKMAN (o `current` é um symlink para a versão default).  
Gradle (sistema de build do Android) usa `JAVA_HOME` para encontrar o Java.  
Quando você muda a versão Java com `sdk use java X.Y.Z`, o symlink `current` é atualizado automaticamente.

---

## `zsh/aliases.zsh` — aliases por categoria

Um **alias** é um atalho: você digita o alias e o shell executa o comando completo.  
`alias gc="git commit -m"` → digitar `gc "mensagem"` executa `git commit -m "mensagem"`.

### Configs
| Alias | Executa | Para quê |
|---|---|---|
| `codebash` | `code ~/.zshrc` | abre o .zshrc (que é o symlink) no VS Code |
| `codegit` | `code ~/.gitconfig` | abre configurações globais do git |
| `reload` | `source ~/.zshrc` | recarrega o shell sem fechar o terminal |
| `dotfiles` | `cd ~/Projects/dotfiles` | vai direto para o repositório de dotfiles |

### Git
| Alias | Executa | Detalhes |
|---|---|---|
| `gst` | `git status` | lista arquivos modificados/staged/untracked |
| `ga arquivo` | `git add arquivo` | adiciona arquivo específico ao stage |
| `gaa` | `git add .` | adiciona TUDO ao stage (cuidado com arquivos indesejados) |
| `gc "msg"` | `git commit -m "msg"` | cria commit com mensagem |
| `gco branch` | `git checkout branch` | troca de branch ou restaura arquivo |
| `gb` | `git branch` | lista branches locais |
| `gp` | `git push` | envia commits para o remoto |
| `gpl` | `git pull` | baixa e integra commits do remoto |
| `gl` | `git log --oneline --graph --decorate --all` | histórico visual em árvore, todas as branches |
| `gd` | `git diff` | mostra diferenças não commitadas |

**Flags do `gl` explicadas:**
- `--oneline` → uma linha por commit (hash + mensagem)
- `--graph` → desenha a árvore de branches com ASCII
- `--decorate` → mostra nomes de branches e tags em cada commit
- `--all` → inclui branches remotas (não só a local atual)

### Navegação
| Alias | Executa | Para quê |
|---|---|---|
| `ll` | `ls -lah` | listagem detalhada com arquivos ocultos e tamanhos legíveis |
| `la` | `ls -A` | lista arquivos incluindo ocultos (sem `.` e `..`) |
| `..` | `cd ..` | sobe um nível de diretório |
| `...` | `cd ../..` | sobe dois níveis |
| `cd-` | `cd ~/Projects` | vai para a pasta de projetos |

**Flags do `ll` explicadas:**
- `-l` → formato longo (permissões, dono, tamanho, data)
- `-a` → inclui arquivos ocultos (começam com `.`)
- `-h` → tamanhos legíveis por humano (KB, MB, GB em vez de bytes)

### IP / Rede
| Alias | Para quê |
|---|---|
| `ip` | consulta seu IP público via OpenDNS (funciona mesmo sem acesso à internet) |
| `localip` | IP local da interface `en0` (geralmente Wi-Fi) |
| `ips` | todos os IPs de todas as interfaces (IPv4 e IPv6) |
| `ifactive` | lista só interfaces de rede que estão ativas no momento |

### Arquivos
```bash
alias delete="trash"
```
Substitui `rm` pelo comando `trash` (instalado pelo Brewfile).  
`rm` deleta permanentemente. `trash` move para a Lixeira (recuperável).  
**Uso:** `delete arquivo.txt` em vez de `rm arquivo.txt`.

### Claude Code
```bash
alias clauded="claude --dangerously-skip-permissions"
```
Inicia o Claude Code sem pedir confirmação para cada operação.  
`--dangerously-skip-permissions` pula todos os prompts de permissão.  
**Use com cuidado** — Claude pode modificar/deletar arquivos sem pedir confirmação.

---

### Expo — Dev Server

```bash
alias es="npx expo start"
```
Inicia o Metro bundler (servidor de desenvolvimento do Expo).  
Abre um QR code para escanear com o app **Expo Go** no celular.  
`npx` executa o pacote sem precisar instalar globalmente.

```bash
alias esd="npx expo start --dev-client"
```
**Preferir este** no dia a dia.  
Inicia o servidor apontando para o **Development Build** (não o Expo Go).  
Necessário quando o projeto usa módulos nativos customizados (câmera, notificações, etc.).  
Expo Go não suporta módulos nativos — Development Build sim.

```bash
alias est="npx expo start --tunnel"
```
Cria um túnel público via ngrok para acessar o servidor de dev.  
Usar quando: dispositivo físico em rede diferente do computador, rede corporativa com firewall, hotspot do celular.  
Mais lento que a conexão local — usar só quando necessário.

```bash
alias esi="npx expo start --ios"
alias esa="npx expo start --android"
```
Inicia o servidor E abre automaticamente no simulador iOS ou emulador Android.  
Equivalente a rodar `es` e depois pressionar `i` ou `a` no terminal.

---

### Expo — Build & Run local

```bash
alias eri="npx expo run:ios"
alias era="npx expo run:android"
```
Compila e instala o app diretamente no simulador/dispositivo.  
Diferente do `es` — esse **builda o código nativo** (Swift/Kotlin).  
Necessário quando: primeira vez rodando, adicionou módulo nativo, mudou configuração nativa.  
Requer Xcode instalado (iOS) ou Android Studio + SDK (Android).

```bash
alias epb="npx expo prebuild"
```
Gera as pastas `ios/` e `android/` com o código nativo do projeto.  
Necessário antes de usar IDEs (Xcode, Android Studio) ou rodar builds locais.  
Lê o `app.config.ts` e `app.json` para configurar os projetos nativos.

```bash
alias epbc="npx expo prebuild --clean"
```
Mesmo que `epb` mas **deleta** as pastas `ios/` e `android/` antes de regerar.  
Usar quando: mudou plugins nativos, erros estranhos após update do SDK, configuração corrompida.

---

### Expo — Pacotes

```bash
alias ei="npx expo install"
```
**SEMPRE usar este** para instalar pacotes em projetos Expo — nunca `npm install` diretamente.  
O `expo install` consulta o SDK atual e instala a versão **compatível** do pacote.  
`npm install` instala a última versão, que pode ser incompatível com seu SDK.  
**Exemplo:** `ei expo-camera` em vez de `npm install expo-camera`.

---

### Expo — Utilitários

```bash
alias elint="npx expo lint"
```
Roda o ESLint com a configuração oficial do Expo.  
Identifica erros de código, padrões ruins, problemas de TypeScript.

```bash
alias econfig="npx expo config"
```
Exibe o `app.config.js/ts` **avaliado** — útil para debugar.  
Mostra os valores finais após processar variáveis de ambiente e funções dinâmicas.

```bash
alias expo-reset="npx expo start --clear"
```
Inicia o servidor limpando o cache do Metro bundler.  
Usar quando: módulo não encontrado, cache corrompido, mudanças não refletindo.  
O `--clear` deleta o cache em `$TMPDIR/metro-*`.

---

### Expo — Combos

```bash
alias expo-ios="npx expo prebuild --clean && npx expo run:ios"
alias expo-android="npx expo prebuild --clean && npx expo run:android"
```
Fluxo completo: limpa pastas nativas, regera e compila.  
Usar quando: adicionou ou removeu um plugin nativo, update de SDK major.  
O `&&` garante que o segundo comando só roda se o primeiro tiver sucesso.

---

### Expo — Criar projetos

```bash
alias expo-new="npx create-expo-app@latest"
```
Template oficial da Expo — Expo Router + TypeScript.  
Mínimo necessário para começar. Sem opinião sobre estado, styling, etc.  
**Uso:** `expo-new NomeDoApp`

```bash
alias expo-new-pro="npx create-obytes-app"
```
Template da comunidade obytes — stack completa de produção:  
Expo Router + NativeWind (Tailwind) + TanStack Query + Zustand + MMKV + CI/CD.  
**Recomendado** para projetos reais — evita configurar tudo na mão.  
**Uso:** `expo-new-pro NomeDoApp`

```bash
alias expo-new-stack="npx create-expo-stack@latest"
```
CLI interativo — pergunta o que você quer usar (routing, styling, backend).  
Bom quando você quer escolher a stack do zero sem remover partes de um template.  
**Uso:** `expo-new-stack` (sem argumentos — começa o wizard interativo)

---

### EAS Build — perfis

O EAS tem 3 perfis de build definidos no `eas.json` de cada projeto:

| Perfil | Para quê | Onde instala |
|---|---|---|
| `development` | dev com módulos nativos | dispositivos internos da equipe |
| `preview` | teste de stakeholders, QA | dispositivos internos (sem App Store) |
| `production` | versão final para lojas | App Store / Google Play |

```bash
alias easd="eas build --profile development"          # todas as plataformas
alias easdi="eas build --profile development --platform ios"
alias easda="eas build --profile development --platform android"

alias easp="eas build --profile preview"              # todas as plataformas
alias easpi="eas build --profile preview --platform ios"
alias easpa="eas build --profile preview --platform android"

alias easprod="eas build --profile production"        # todas as plataformas
alias easprodi="eas build --profile production --platform ios"
alias easproda="eas build --profile production --platform android"
```

**Convenção dos nomes:**
- `d` = development, `p` = preview, `prod` = production
- `i` no final = iOS only
- `a` no final = Android only
- sem sufixo = ambas as plataformas

---

### EAS Update / Submit

```bash
alias easu="eas update"
```
Publica uma atualização OTA (Over The Air) — atualiza o JS sem novo build.  
Funciona para mudanças que não tocam código nativo.  
**Não funciona** para: novos módulos nativos, mudanças em `app.json`, plugins.

```bash
alias easum="eas update --branch main"
```
Publica OTA na branch `main` — os dispositivos que usam essa branch recebem automaticamente.  
Útil para hotfixes rápidos em produção.

```bash
alias eassubi="eas submit --platform ios"
alias eassuba="eas submit --platform android"
```
Envia o build mais recente para a App Store (iOS) ou Google Play (Android).  
Requer credenciais configuradas — `eas credentials` para configurar.

```bash
alias easinfo="eas project:info"
```
Exibe informações do projeto no EAS: ID, owner, builds recentes, canais.

---

## `Brewfile` — gerenciador de pacotes

O Brewfile é lido pelo comando `brew bundle`. Funciona como um `package.json` para apps do macOS.

### Taps
```
tap "xcodesorg/made"
```
Adiciona um repositório de fórmulas de terceiros ao Homebrew.  
Necessário para instalar ferramentas do ecossistema `xcodesorg` (como `xcodes`).

### `brew` vs `cask`
- `brew "pacote"` → instala **ferramentas CLI** (sem interface gráfica)
- `cask "app"` → instala **apps macOS** (com interface gráfica, vão para `/Applications`)

### CLI Tools explicados
| Pacote | Por que está aqui |
|---|---|
| `git` | versão atualizada do git (macOS vem com versão antiga) |
| `bash` | bash 5+ necessário para o SDKMAN funcionar (macOS vem com bash 3.2) |
| `aria2` | download com múltiplas conexões paralelas — acelera downloads grandes |
| `watchman` | monitora mudanças em arquivos — o Metro bundler do Expo usa para hot reload |
| `mas` | controla o Mac App Store pelo terminal — usado para instalar Xcode |
| `trash` | move arquivos para a Lixeira (`alias delete="trash"`) em vez de deletar permanentemente |
| `node` | runtime JavaScript — necessário para npm, npx, EAS CLI |

### Apps (casks) explicados
| App | Por que está aqui |
|---|---|
| `arc` | browser com workspaces, tabs por projeto, muito usado por devs |
| `google-chrome` | testes de compatibilidade web, DevTools |
| `firefox` | testes de compatibilidade web |
| `slack` | comunicação de equipes |
| `discord` | comunidades técnicas, suporte de libs |
| `claude` | app desktop do Claude (Anthropic) |
| `raycast` | substitui o Spotlight — mais rápido, extensões para GitHub/Jira/etc. |
| `notion` | documentação e notas do projeto |
| `visual-studio-code` | editor de código principal |
| `intellij-idea` | IDE para projetos Java/Kotlin (Android nativo, backend) |
| `cursor` | VS Code com AI integrada — autocomplete e chat com contexto do projeto |
| `warp` | terminal com AI, histórico persistente, blocos de output |
| `postman` | teste manual de APIs REST/GraphQL |
| `tableplus` | cliente GUI para databases (Postgres, MySQL, SQLite, Redis) |
| `docker` | Docker Desktop — containers para rodar serviços locais (banco, cache, etc.) |
| `android-studio` | IDE oficial Android + emulador + Android SDK + build tools |

### Manutenção do Brewfile

```bash
# Instalar tudo que está no Brewfile (novos itens)
brew bundle --file=~/Projects/dotfiles/Brewfile

# Verificar o que está instalado vs o que está no Brewfile
brew bundle check --file=~/Projects/dotfiles/Brewfile

# Remover apps que não estão mais no Brewfile
brew bundle cleanup --file=~/Projects/dotfiles/Brewfile

# Adicionar um novo app ao Brewfile
echo 'cask "nome-do-app"' >> ~/Projects/dotfiles/Brewfile
```

---

## `scripts/install.sh` — bootstrap

Script que configura tudo do zero em uma máquina nova.

### Cabeçalho
```bash
#!/usr/bin/env bash
```
Shebang — diz ao sistema para usar o bash encontrado no PATH (em vez de hardcodar `/bin/bash`).  
Importante porque o macOS tem bash 3.2 em `/bin/bash`, mas instalamos o bash 5 via brew.

```bash
set -e
```
Para o script imediatamente se qualquer comando falhar.  
Sem isso, um erro no meio do script seria ignorado e os próximos passos rodariam com estado inválido.

```bash
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
```
Descobre o caminho absoluto do repositório dotfiles, independente de onde o script é chamado.  
`${BASH_SOURCE[0]}` → caminho do script atual (`scripts/install.sh`)  
`dirname` → pega só a pasta (`scripts/`)  
`cd .. && pwd` → sobe um nível e retorna o caminho absoluto (`/Users/xxx/Projects/dotfiles`)

### Funções de log
```bash
log()    { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }    # seção principal
ok()     { echo -e "  ${GREEN}✅ $1${NC}"; }          # sucesso
warn()   { echo -e "  ${YELLOW}⚠️  $1${NC}"; }        # aviso
fail()   { echo -e "  ${RED}❌ $1${NC}"; }            # erro
```
Funções auxiliares para output colorido e consistente.  
`\033[0;32m` são códigos ANSI de cor. `NC` = No Color (reset).

### Passo 1 — Homebrew
```bash
if ! command -v brew &>/dev/null; then
```
`command -v brew` testa se `brew` existe no PATH.  
`!` inverte — entra no if só se **não** existir.  
`&>/dev/null` redireciona stdout e stderr para /dev/null (silencia o output).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Baixa e executa o instalador oficial do Homebrew.  
`curl -fsSL`: `-f` falha silenciosamente em erros HTTP, `-s` silencioso, `-S` mostra erros, `-L` segue redirects.

```bash
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
```
Após instalar, configura as variáveis de ambiente do Homebrew para o script atual.  
Sem isso, `brew` não estaria disponível no restante do script.  
`eval` executa o output do comando (adiciona brew ao PATH da sessão atual).

### Passo 2 — Brewfile
```bash
brew bundle --file="$DOTFILES/Brewfile" --no-lock
```
Instala todos os itens do Brewfile.  
`--no-lock` não cria/atualiza o `Brewfile.lock.json` (arquivo de versões fixas).  
Omitimos o lock porque preferimos sempre instalar as versões mais recentes.

### Passo 3 — SDKMAN
```bash
if [[ ! -d "$HOME/.sdkman" ]]; then
```
Verifica se a pasta `~/.sdkman` já existe antes de instalar.  
Evita reinstalar e sobrescrever configurações existentes.

```bash
curl -s "https://get.sdkman.io" | bash
```
Baixa e executa o instalador do SDKMAN.  
SDKMAN gerencia múltiplas versões de Java, Kotlin, Gradle, Maven, etc.

```bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```
Carrega o SDKMAN no contexto do script para que o comando `sdk` esteja disponível nos passos seguintes.

### Passo 4 — Java 17
```bash
if ! sdk list java 2>/dev/null | grep -q "17.0.11-tem.*installed"; then
```
Verifica se o Java 17 Temurin já está instalado antes de baixar novamente.  
`grep -q` — modo silencioso, só retorna o código de saída (0=encontrou, 1=não encontrou).

```bash
sdk install java 17.0.11-tem
```
Instala Java 17.0.11 distribuição Temurin (Eclipse Foundation — versão open-source do OpenJDK).  
Temurin é a distribuição recomendada para Android builds por ser LTS e bem mantida.

```bash
sdk default java 17.0.11-tem
```
Define esta versão como padrão para todas as sessões de terminal.  
Cria o symlink `~/.sdkman/candidates/java/current` → `17.0.11-tem`.

### Passo 5 — EAS CLI
```bash
npm install -g eas-cli 2>/dev/null
```
Instala o EAS CLI globalmente via npm.  
`-g` = global (disponível em qualquer diretório).  
`2>/dev/null` silencia warnings do npm (funding messages, etc.).

### Passo 6 — Symlink .zshrc
```bash
if [[ -f "$ZSHRC_TARGET" && ! -L "$ZSHRC_TARGET" ]]; then
```
`-f` verifica se é um arquivo regular (não symlink).  
`! -L` verifica que NÃO é um symlink já existente.  
Só faz backup se for um arquivo real — evita backup de symlink.

```bash
ln -sf "$ZSHRC_SOURCE" "$ZSHRC_TARGET"
```
Cria um symlink.  
`-s` = symbolic link (em vez de hard link).  
`-f` = force (sobrescreve se já existir).  
Resultado: `~/.zshrc` → `~/Projects/dotfiles/zsh/.zshrc`.

### Passos 7 e 8 — Xcode e Android Studio
Apenas verificam se já estão instalados e exibem avisos se não estiverem.  
Xcode não pode ser automatizado (App Store).  
Android Studio é instalado pelo Brewfile — o script só lembra de configurar o SDK dentro dele.

---

## Comandos de manutenção

### Adicionar novo alias
```bash
# 1. Editar o arquivo de aliases
code ~/Projects/dotfiles/zsh/aliases.zsh

# 2. Recarregar o shell
reload

# 3. Commitar
cd ~/Projects/dotfiles
gaa && gc "feat: add alias xyz"
gp
```

### Adicionar novo app
```bash
# 1. Adicionar ao Brewfile
echo 'cask "nome-do-app"' >> ~/Projects/dotfiles/Brewfile

# 2. Instalar
brew bundle --file=~/Projects/dotfiles/Brewfile

# 3. Commitar
cd ~/Projects/dotfiles
gaa && gc "feat: add nome-do-app to Brewfile"
gp
```

### Adicionar nova variável de ambiente
```bash
# 1. Editar exports.zsh
code ~/Projects/dotfiles/zsh/exports.zsh

# 2. Recarregar
reload

# 3. Commitar
cd ~/Projects/dotfiles
gaa && gc "feat: add MY_VAR env variable"
gp
```

### Atualizar Java para nova versão
```bash
# Ver versões disponíveis
sdk list java

# Instalar nova versão
sdk install java 21.0.3-tem

# Definir como padrão
sdk default java 21.0.3-tem

# Verificar
java -version
```

### Atualizar todos os pacotes brew
```bash
brew update && brew upgrade && brew upgrade --cask
```

### Sincronizar dotfiles em outra máquina
```bash
# Na nova máquina:
git clone https://github.com/genorchiomento/dotfiles.git ~/Projects/dotfiles
bash ~/Projects/dotfiles/scripts/install.sh
source ~/.zshrc
```
