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
│   └── install.sh        → bootstrap com menu de seleção + coleta de erros
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

Script que configura o ambiente. Dois princípios de design:

1. **Seleção** — você escolhe o que instalar numa lista navegável por setas, categoria a categoria ou app a app.
2. **Nunca aborta** — se um app falhar, o script continua, configura todo o resto, e lista as falhas juntas no resumo final.

### Modos de uso
```bash
bash scripts/install.sh                    # menu interativo
bash scripts/install.sh --all              # instala tudo, sem perguntar
bash scripts/install.sh --only=dev,browsers  # só essas categorias
bash scripts/install.sh --only=1,4          # idem, por número
bash scripts/install.sh --dry-run           # mostra o plano, não instala
bash scripts/install.sh --list              # lista as categorias
bash scripts/install.sh --help
```

`--only` casa por número da categoria **ou** por parte do nome (case-insensitive).
`--dry-run` combina com qualquer modo.

### O menu — TUI navegável por setas

```
    [x] ▸ CLI Tools                 6/6
    [x] ▸ Languages / Runtimes      1/1
    [ ] ▸ Browsers                  0/3
  ❯ [~] ▾ Dev Tools                 5/7
        [x] visual-studio-code      editor
        [ ] intellij-idea           IntelliJ IDEA Ultimate
      ▼ mais abaixo

  ↑↓ mover   → abrir   ← fechar   espaço marcar
  a tudo    n nada    ENTER instalar   q sair
```

| Marca | Significado |
|---|---|
| `[x]` | tudo selecionado |
| `[ ]` | nada selecionado |
| `[~]` | seleção parcial |
| `▸` / `▾` | categoria fechada / aberta |

| Tecla | Ação |
|---|---|
| `↑` `↓` / `k` `j` | mover o cursor |
| `→` / `l` | abrir a categoria; se já aberta, desce pro primeiro app |
| `←` / `h` | fechar a categoria; de dentro dela, fecha e volta pro cabeçalho |
| `espaço` | alterna — na linha de categoria vale pra todos os apps dela |
| `a` / `n` | marcar tudo / desmarcar tudo |
| `ENTER` | instalar |
| `q` | sair |

**Sem dependências externas.** Nada de `fzf`, `gum` ou `dialog`: o script roda numa máquina zerada, antes de qualquer coisa estar instalada. Tudo é bash 3.2 + ANSI.

### Como a TUI funciona

**Modelo de linhas achatado.** Categorias e apps não são telas separadas — são uma lista só, reconstruída sempre que uma categoria abre ou fecha:

```bash
CAT_OPEN=()                            # 1 = categoria expandida
ROW_TYPE=(); ROW_CAT=(); ROW_ITEM=()   # linhas visíveis
CUR=0; VP=0                            # cursor e topo do viewport
```

`build_rows()` percorre as categorias e, para cada uma aberta, insere as linhas dos apps logo abaixo. `CUR` é índice em `ROW_*`, então mover o cursor é aritmética simples — não precisa saber se está numa categoria ou num app até a hora de agir.

**Leitura de teclas e o problema do ESC.** Uma seta chega como 3 bytes: `ESC` `[` `A`. Um ESC solto chega como 1 byte. TUIs normalmente distinguem os dois com um timeout de milissegundos — mas o bash 3.2 do macOS não aceita `read -t` fracionário:

```
$ /bin/bash -c 'read -t 0.05 x'
read: 0.05: invalid timeout specification
```

Solução: em vez de esperar, lê o próximo byte e devolve pro buffer se não fizer parte de uma sequência de seta.

```bash
KEYBUF=""
_getch() {
  if [ -n "$KEYBUF" ]; then CH="${KEYBUF:0:1}"; KEYBUF="${KEYBUF:1}"; return 0; fi
  IFS= read -rsn1 CH
}
```

`IFS=` é obrigatório — sem isso o `read -n1` engole o espaço, que é justamente a tecla de marcar. No `case`, `''` é ENTER (com `-n1` o delimitador newline retorna string vazia).

**Render sem flicker.** Não usa `clear` a cada frame — isso pisca. Em vez disso volta o cursor pro topo (`\033[H`), reescreve cada linha terminando com `\033[K` (limpa até o fim da linha) e no final `\033[J` (limpa o resto da tela). O cursor fica escondido durante a navegação (`tput civis`) e um `trap ... INT` garante que ele volta se você der Ctrl+C.

**Viewport.** `avail = $(tput lines) - 13` (cabeçalho + rodapé). O topo da janela (`VP`) é ajustado a cada render pra conter o cursor, e as setas `▲`/`▼` aparecem quando há conteúdo fora da tela. Recalculado a cada frame, então redimensionar o terminal funciona.

### Catálogo — Brewfile é a fonte da verdade

O script **não** tem lista de apps hardcoded. Ele parseia o Brewfile:

```bash
'# ──'*)   # header vira categoria
  name="$(printf '%s' "$line" | sed -e 's/^# ──[[:space:]]*//' -e 's/[[:space:]]*─*[[:space:]]*$//')"
brew*'"'*|cask*'"'*)   # linha vira item, comentário vira descrição
  id="$(printf '%s'   "$line" | sed -n 's/^[a-z]*[[:space:]]*"\([^"]*\)".*/\1/p')"
  desc="$(printf '%s' "$line" | sed -n 's/^[^#]*#[[:space:]]*//p')"
```

Consequência prática: **adicionar um app ao Brewfile já o faz aparecer no menu.** Nada a atualizar no script.
Um header `# ── Nome ──` só vira categoria se tiver pelo menos um `brew`/`cask` embaixo (por isso o header "Xcode" do Brewfile, que só tem comentários, não gera categoria vazia).

Depois do parse, o script acrescenta 3 categorias que não são pacotes brew:

| Categoria | Itens |
|---|---|
| Toolchain Mobile | `sdkman`, `java17`, `eascli` |
| Shell | `zshrc` (symlink) |
| Xcode | `xcode` (xcode-select + licença) |

### Estruturas de dados

Arrays indexados paralelos — **não** associativos (`declare -A`), porque o macOS traz bash 3.2 e o script precisa rodar antes do bash 5 ser instalado:

```bash
CAT_NAME=()                                  # nomes das categorias
ITEM_CAT=(); ITEM_TYPE=(); ITEM_ID=()        # índice da categoria, brew|cask|step, nome
ITEM_DESC=(); ITEM_SEL=()                    # descrição, 1|0 selecionado
```

Pelo mesmo motivo o script evita `mapfile`, `${var,,}` e `set -e`.

### Por que não tem `set -e`

`set -e` aborta no primeiro erro — exatamente o oposto do que queremos. Se o Docker falhar, o `.zshrc` ainda precisa ser configurado. O controle de erro é explícito:

```bash
capture() {   # roda o comando, guarda saída em LAST_OUT + log, devolve o rc
  LAST_OUT="$("$@" 2>&1)"; local rc=$?
  { echo "\$ $*"; printf '%s\n' "$LAST_OUT"; echo "--- rc=$rc"; } >> "$LOG"
  return $rc
}

record_fail() { FAIL_NAME+=("$1"); FAIL_MSG+=("$2"); fail "$1 — $2"; }
```

Cada instalação vira `if capture ...; then ok; else record_fail; fi`. O loop nunca para.

### Contadores e coleta

```bash
OK_COUNT=0; SKIP_COUNT=0
FAIL_NAME=(); FAIL_MSG=()   # falhas: nome + causa
WARN_MSG=()                 # não-fatais (ex: sdk default falhou)
NOTE_MSG=()                 # próximos passos manuais
```

`last_error_line()` filtra a saída do comando por `error|fatal|denied|not found|failed` e pega a última linha — é isso que aparece no resumo, em vez de despejar 200 linhas de log.

### sudo: pedir uma vez, com contexto

Casks com artefato `binary` criam symlinks em `/usr/local/bin`. Em Apple Silicon o brew mora em `/opt/homebrew` (do usuário), mas `/usr/local` continua do root:

```
drwxr-xr-x  7 root  wheel  /usr/local
drwxr-xr-x@ 12 root wheel  /usr/local/bin
```

O Docker sozinho cria 6 symlinks lá (`docker`, `docker-compose`, `kubectl.docker`, os três `docker-credential-*`). Daí o sudo.

O problema não era o sudo em si, era **quando** ele aparecia. O `capture()` roda o comando dentro de `$(...)`, engolindo stdout e stderr — então toda explicação do brew some. O prompt do sudo sobrevive porque o sudo escreve em `/dev/tty`, que escapa da substituição de comando:

```
$ script -q /dev/null bash -c 'out="$( { echo PROMPT > /dev/tty; } 2>&1; echo normal )"; echo "LAST_OUT=[$out]"'
PROMPT
LAST_OUT=[normal]
```

Resultado prático: um `Password:` pelado no meio da instalação, sem dizer quem pediu. E como o timestamp do sudo expira em 5 minutos, ele repergunta em instalações longas.

`sudo_prewarm()` resolve pedindo uma vez no início, com explicação, e só quando faz sentido:

```bash
needs_sudo() {   # só se a seleção tiver algum cask ou o passo do Xcode
  ...
}
```

Depois um keepalive em background renova o timestamp enquanto o script roda:

```bash
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
SUDO_PID=$!
disown 2>/dev/null || true   # senão o shell imprime "Terminated: 15" ao matar
```

`$$` dentro do subshell continua sendo o PID do script (não do subshell), então o keepalive morre junto com ele. Um `trap 'sudo_stop' EXIT` garante a limpeza — e o `trap` não altera o exit code do script.

Recusar a senha não aborta nada: vira um aviso no resumo e o script segue com o que não precisa de root.

### Idempotência

Todo item checa antes de instalar:

| Tipo | Checagem | Resultado |
|---|---|---|
| `brew` | `brew list --formula <id>` | `⏭  já instalado` |
| `cask` | `brew list --cask <id>` | `⏭  já instalado` |
| sdkman | `-d ~/.sdkman` | pula |
| java17 | `sdk list java \| grep 17.0.11-tem.*installed` | pula |
| eascli | `command -v eas` | pula |
| zshrc | `readlink ~/.zshrc` == origem | pula |

Rodar de novo é barato — só instala o que falta.

### Casks: `--adopt`

```bash
brew install --cask --adopt "$1" || brew install --cask "$1"
```

`--adopt` faz o brew assumir o controle de um app que já está em `/Applications` mas foi instalado manualmente — sem isso o brew falha com *"It seems there is already an App at..."*. O fallback sem a flag cobre versões antigas do Homebrew que não a conhecem.

### Dependências entre etapas

Etapas dependentes não travam o script — viram falha com a causa explícita:

```bash
step_java17() {
  if [ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    record_fail "java17" "SDKMAN ausente — selecione/instale SDKMAN antes"
    return
  fi
```

Mesmo padrão em `step_eascli` (precisa de `npm`) e nos itens brew/cask (precisam do Homebrew: se o brew falhar, todos são marcados `pulado: Homebrew indisponível` em vez de gerar N erros idênticos).

### `pad()` em vez de `printf %-24s`

```bash
pad() { local s="$1" w="$2"; while [ ${#s} -lt "$w" ]; do s="$s "; done; printf '%s' "$s"; }
```

O `printf` do bash conta o campo em **bytes**; `${#s}` conta **caracteres**. Com "Comunicação" (ç e ã ocupam 2 bytes cada em UTF-8) o `%-24s` desalinharia a coluna em 2 espaços. `pad()` alinha certo.

### Relatório de configuração

Contar apps instalados não conta a história toda — aliases, variáveis de ambiente e toolchain também foram aplicados. `config_report()` inspeciona o **estado real** depois da instalação, em vez de repetir o que o script tentou fazer.

**Aliases por categoria** saem de um awk sobre o próprio `aliases.zsh`, usando os headers `# === Nome ===` como divisores:

```bash
awk '
  /^# === / { name = $0; sub(/^# === /, "", name); sub(/ ===$/, "", name)
              cats[++k] = name; next }
  /^[[:space:]]*alias / { if (k > 0) cnt[k]++ }
  END { for (i = 1; i <= k; i++) printf "%s\t%d\n", cats[i], cnt[i] + 0 }
' "$1"
```

O `[[:space:]]*` importa: aliases guardados por condição são indentados (`  alias hotmart=...`) e um `^alias` puro não os pegaria.

**A verificação de verdade** não é contar linhas do arquivo — é abrir um zsh e ver o que ele carregou:

```bash
comm -12 \
  <(grep -Eo '^[[:space:]]*alias [A-Za-z0-9_.:-]+' "$af" | awk '{print $NF}' | sort -u) \
  <(zsh -ic 'alias' 2>/dev/null | sed 's/=.*//' | sort -u) | grep -c .
```

Interseção, não contagem total: o zsh já traz 2 aliases próprios (`run-help`, `which-command`), então um `alias | wc -l` daria 60 onde o arquivo tem 58 e pareceria um bug. Comparando nome a nome, `58 de 58` é uma afirmação verificável.

**Variáveis de ambiente** vêm do `exports.zsh`, com `$HOME` substituído textualmente (não via `eval`) e um teste de existência do diretório. `ANDROID_HOME` aparece com `⚠️` até você abrir o Android Studio e instalar o SDK — o que é o estado correto, não um erro.

O `PATH` é reportado como contagem de entradas em vez de valor: ele é montado em 3 `export` separados no `exports.zsh` e imprimir o valor final não diria nada útil.

### Resumo final

```
  RESUMO

    ✅ aplicados:    14
    ⏭  já presentes: 3
    ⚠️  avisos:      1
    ❌ falhas:      2

  Falhas — o resto foi configurado normalmente
    ❌ docker
       brew install --cask falhou: Error: Cask 'docker' is unavailable.

    Log completo: ~/.dotfiles-install-20260819_095441.log

  Próximos passos
    → source ~/.zshrc — recarregar o shell
    → Android Studio → SDK Manager → instalar Android SDK API 34
```

Exit code: `0` sem falhas, `1` com falhas — dá pra usar em CI ou encadear com `&&`.
O log completo (todo comando + saída + rc) fica em `~/.dotfiles-install-<timestamp>.log`.

### Para reinstalar só o que falhou

```bash
bash scripts/install.sh             # menu → n (desmarca tudo) → marca só os itens que falharam
bash scripts/install.sh --only=7    # ou a categoria inteira (idempotente: pula os que já foram)
```


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
