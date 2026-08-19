#!/usr/bin/env bash
# ============================================================
# install.sh — bootstrap do ambiente de desenvolvimento
#
# Uso:
#   bash scripts/install.sh              # menu interativo
#   bash scripts/install.sh --all        # instala tudo, sem menu
#   bash scripts/install.sh --only=dev,browsers
#   bash scripts/install.sh --dry-run    # mostra o plano, não instala
#   bash scripts/install.sh --list       # lista categorias
#
# Nunca aborta no meio: erros são coletados e reportados no final.
# ============================================================

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREWFILE="$DOTFILES/Brewfile"
LOG="$HOME/.dotfiles-install-$(date +%Y%m%d_%H%M%S).log"

BOLD='\033[1m'; DIM='\033[2m'
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'
RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

log()     { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }
ok()      { echo -e "  ${GREEN}✅ $1${NC}"; }
skip()    { echo -e "  ${DIM}⏭  $1${NC}"; }
warn()    { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
fail()    { echo -e "  ${RED}❌ $1${NC}"; }
divider() { echo -e "${BOLD}────────────────────────────────────────────────${NC}"; }

banner() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║          dotfiles — setup automático         ║${NC}"
  echo -e "${BOLD}║          macOS (Apple Silicon)               ║${NC}"
  echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── Flags ──────────────────────────────────────────────────
MODE="menu"; DRY_RUN=0; ONLY=""
for arg in "$@"; do
  case "$arg" in
    --all)      MODE="all" ;;
    --only=*)   MODE="only"; ONLY="${arg#--only=}" ;;
    --dry-run)  DRY_RUN=1 ;;
    --list)     MODE="list" ;;
    -h|--help)  MODE="help" ;;
    *) echo "Flag desconhecida: $arg (use --help)"; exit 2 ;;
  esac
done

show_help() {
  banner
  cat <<'H'
  Uso: bash scripts/install.sh [flags]

    (sem flags)        menu interativo por categoria
    --all              instala tudo, sem perguntar
    --only=a,b         só as categorias indicadas (número ou parte do nome)
    --dry-run          mostra o que seria feito, sem instalar
    --list             lista as categorias disponíveis
    -h, --help         esta ajuda

  Exemplos:
    bash scripts/install.sh --only=dev,browsers
    bash scripts/install.sh --only=1,4 --dry-run
    bash scripts/install.sh --all

  Erros não interrompem a instalação: tudo que der certo é configurado,
  e as falhas aparecem juntas no resumo final (log completo em ~/.dotfiles-install-*.log).
H
  echo ""
}

# ── Catálogo ───────────────────────────────────────────────
# Categorias vêm do Brewfile (headers "# ── Nome ──"), mais as
# etapas extras definidas abaixo. Brewfile = fonte única da verdade.

CAT_NAME=()
ITEM_CAT=(); ITEM_TYPE=(); ITEM_ID=(); ITEM_DESC=(); ITEM_SEL=()
TAPS=()
CUR_CAT=-1

add_cat()  { CAT_NAME+=("$1"); CUR_CAT=$(( ${#CAT_NAME[@]} - 1 )); }
add_item() { # add_item <type> <id> <desc>
  ITEM_CAT+=("$CUR_CAT"); ITEM_TYPE+=("$1"); ITEM_ID+=("$2")
  ITEM_DESC+=("$3");      ITEM_SEL+=(1)
}

parse_brewfile() {
  local line pending="" id desc name
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '# ──'*)
        name="$(printf '%s' "$line" | sed -e 's/^# ──[[:space:]]*//' -e 's/[[:space:]]*─*[[:space:]]*$//')"
        [ -n "$name" ] && pending="$name"
        ;;
      tap*'"'*)
        TAPS+=("$(printf '%s' "$line" | sed -n 's/^tap[[:space:]]*"\([^"]*\)".*/\1/p')")
        ;;
      brew*'"'*|cask*'"'*)
        if [ -n "$pending" ]; then add_cat "$pending"; pending=""; fi
        [ "$CUR_CAT" -lt 0 ] && continue
        id="$(printf '%s'   "$line" | sed -n 's/^[a-z]*[[:space:]]*"\([^"]*\)".*/\1/p')"
        desc="$(printf '%s' "$line" | sed -n 's/^[^#]*#[[:space:]]*//p')"
        [ -z "$id" ] && continue
        case "$line" in brew*) add_item brew "$id" "$desc" ;; *) add_item cask "$id" "$desc" ;; esac
        ;;
    esac
  done < "$BREWFILE"
}

build_catalog() {
  if [ ! -f "$BREWFILE" ]; then
    fail "Brewfile não encontrado em $BREWFILE"; exit 1
  fi
  parse_brewfile

  add_cat "Toolchain Mobile"
  add_item step sdkman  "SDKMAN (gerenciador de SDKs Java)"
  add_item step java17  "Java 17 Temurin (builds Android)"
  add_item step eascli  "EAS CLI (Expo build service)"

  add_cat "Shell"
  add_item step zshrc   "symlink ~/.zshrc → dotfiles/zsh/.zshrc"

  add_cat "Xcode"
  add_item step xcode   "xcode-select + aceitar licença"
}

# ── Estado de seleção ──────────────────────────────────────
CNT_SEL=0; CNT_TOT=0
count_cat() { # count_cat <cat_idx>
  local i=0; CNT_SEL=0; CNT_TOT=0
  while [ $i -lt ${#ITEM_ID[@]} ]; do
    if [ "${ITEM_CAT[$i]}" -eq "$1" ]; then
      CNT_TOT=$(( CNT_TOT + 1 ))
      [ "${ITEM_SEL[$i]}" -eq 1 ] && CNT_SEL=$(( CNT_SEL + 1 ))
    fi
    i=$(( i + 1 ))
  done
}

set_all() { # set_all <0|1>
  local i=0
  while [ $i -lt ${#ITEM_SEL[@]} ]; do ITEM_SEL[$i]=$1; i=$(( i + 1 )); done
}

set_cat() { # set_cat <cat_idx> <0|1>
  local i=0
  while [ $i -lt ${#ITEM_ID[@]} ]; do
    [ "${ITEM_CAT[$i]}" -eq "$1" ] && ITEM_SEL[$i]=$2
    i=$(( i + 1 ))
  done
}

toggle_cat() { # marca tudo se não estiver tudo marcado; senão desmarca
  count_cat "$1"
  if [ "$CNT_SEL" -eq "$CNT_TOT" ]; then set_cat "$1" 0; else set_cat "$1" 1; fi
}

# padding correto com acentos (printf %-Ns conta bytes, ${#s} conta chars)
pad() { local s="$1" w="$2"; while [ ${#s} -lt "$w" ]; do s="$s "; done; printf '%s' "$s"; }

# ── TUI: navegação por setas ───────────────────────────────
# Sem dependências externas (fzf/gum/dialog): o script roda numa máquina
# zerada, antes de qualquer coisa estar instalada. Tudo em bash 3.2.

CAT_OPEN=()                       # 1 = categoria expandida
ROW_TYPE=(); ROW_CAT=(); ROW_ITEM=()   # linhas visíveis (achatadas)
CUR=0; VP=0                       # cursor e topo do viewport
KEYBUF=""                         # pushback de teclas

init_open() { local c=0; while [ $c -lt ${#CAT_NAME[@]} ]; do CAT_OPEN[$c]=0; c=$(( c + 1 )); done; }

build_rows() {
  ROW_TYPE=(); ROW_CAT=(); ROW_ITEM=()
  local c=0 i
  while [ $c -lt ${#CAT_NAME[@]} ]; do
    ROW_TYPE+=("c"); ROW_CAT+=("$c"); ROW_ITEM+=("-1")
    if [ "${CAT_OPEN[$c]}" -eq 1 ]; then
      i=0
      while [ $i -lt ${#ITEM_ID[@]} ]; do
        if [ "${ITEM_CAT[$i]}" -eq "$c" ]; then
          ROW_TYPE+=("i"); ROW_CAT+=("$c"); ROW_ITEM+=("$i")
        fi
        i=$(( i + 1 ))
      done
    fi
    c=$(( c + 1 ))
  done
}

row_of_cat() { # primeira linha da categoria $1
  local r=0
  while [ $r -lt ${#ROW_TYPE[@]} ]; do
    [ "${ROW_TYPE[$r]}" = "c" ] && [ "${ROW_CAT[$r]}" -eq "$1" ] && { echo "$r"; return; }
    r=$(( r + 1 ))
  done
  echo 0
}

# ── Leitura de teclas ──────────────────────────────────────
# bash 3.2 não tem `read -t` fracionário, então não dá pra distinguir ESC
# solto de uma sequência de seta por timeout. Em vez disso: lê o próximo
# byte e, se não for '[' nem 'O', devolve pro buffer (pushback).
_getch() {
  if [ -n "$KEYBUF" ]; then CH="${KEYBUF:0:1}"; KEYBUF="${KEYBUF:1}"; return 0; fi
  IFS= read -rsn1 CH
}

read_key() {
  _getch || { echo eof; return; }
  case "$CH" in
    '')   echo enter ;;
    ' ')  echo space ;;
    $'\e')
      _getch || { echo esc; return; }
      case "$CH" in
        '['|'O')
          _getch || { echo esc; return; }
          case "$CH" in
            A) echo up ;; B) echo down ;; C) echo right ;; D) echo left ;;
            *) echo other ;;
          esac ;;
        *) KEYBUF="$CH$KEYBUF"; echo esc ;;
      esac ;;
    k|K) echo up    ;; j|J) echo down  ;;
    l|L) echo right ;; h|H) echo left  ;;
    a|A) echo all   ;; n|N) echo none  ;;
    q|Q) echo quit  ;;
    *)   echo other ;;
  esac
}

# ── Render ─────────────────────────────────────────────────
total_selected() {
  local i=0 n=0
  while [ $i -lt ${#ITEM_SEL[@]} ]; do [ "${ITEM_SEL[$i]}" -eq 1 ] && n=$(( n + 1 )); i=$(( i + 1 )); done
  echo "$n"
}

tui_render() {
  local h=24 w=80
  command -v tput >/dev/null 2>&1 && { h=$(tput lines 2>/dev/null || echo 24); w=$(tput cols 2>/dev/null || echo 80); }
  local avail=$(( h - 13 )); [ "$avail" -lt 4 ] && avail=4
  local nrows=${#ROW_TYPE[@]}

  [ "$CUR" -lt 0 ] && CUR=0
  [ "$CUR" -ge "$nrows" ] && CUR=$(( nrows - 1 ))
  [ "$CUR" -lt "$VP" ] && VP="$CUR"
  [ "$CUR" -ge $(( VP + avail )) ] && VP=$(( CUR - avail + 1 ))
  [ "$VP" -lt 0 ] && VP=0

  printf '\033[H'
  printf '%b\n' "\033[K"
  printf '%b\n' "${BOLD}  ╔══════════════════════════════════════════════╗${NC}\033[K"
  printf '%b\n' "${BOLD}  ║          dotfiles — setup automático         ║${NC}\033[K"
  printf '%b\n' "${BOLD}  ╚══════════════════════════════════════════════╝${NC}\033[K"
  printf '%b\n' "\033[K"
  printf '%b\n' "  ${BOLD}O que instalar?${NC}  ${DIM}$(total_selected) de ${#ITEM_ID[@]} itens marcados${NC}\033[K"
  printf '%b\n' "\033[K"

  if [ "$VP" -gt 0 ]; then printf '%b\n' "      ${DIM}▲ mais acima${NC}\033[K"; else printf '%b\n' "\033[K"; fi

  local r="$VP" last=$(( VP + avail )) mark arrow cur line desc maxdesc
  [ "$last" -gt "$nrows" ] && last="$nrows"
  while [ "$r" -lt "$last" ]; do
    [ "$r" -eq "$CUR" ] && cur="${BOLD}${CYAN}❯${NC}" || cur=" "
    if [ "${ROW_TYPE[$r]}" = "c" ]; then
      count_cat "${ROW_CAT[$r]}"
      if   [ "$CNT_SEL" -eq 0 ];          then mark="${DIM}[ ]${NC}"
      elif [ "$CNT_SEL" -eq "$CNT_TOT" ]; then mark="${GREEN}[x]${NC}"
      else                                     mark="${YELLOW}[~]${NC}"; fi
      [ "${CAT_OPEN[${ROW_CAT[$r]}]}" -eq 1 ] && arrow="▾" || arrow="▸"
      line="  $cur $mark $arrow $(pad "${CAT_NAME[${ROW_CAT[$r]}]}" 26)${DIM}$CNT_SEL/$CNT_TOT${NC}"
    else
      local it="${ROW_ITEM[$r]}"
      [ "${ITEM_SEL[$it]}" -eq 1 ] && mark="${GREEN}[x]${NC}" || mark="${DIM}[ ]${NC}"
      maxdesc=$(( w - 44 )); [ "$maxdesc" -lt 10 ] && maxdesc=10
      desc="${ITEM_DESC[$it]}"
      [ ${#desc} -gt "$maxdesc" ] && desc="${desc:0:$(( maxdesc - 1 ))}…"
      line="  $cur     $mark $(pad "${ITEM_ID[$it]}" 24)${DIM}$desc${NC}"
    fi
    printf '%b\n' "$line\033[K"
    r=$(( r + 1 ))
  done

  local blank=$(( avail - ( last - VP ) ))
  while [ "$blank" -gt 0 ]; do printf '%b\n' "\033[K"; blank=$(( blank - 1 )); done

  if [ "$last" -lt "$nrows" ]; then printf '%b\n' "      ${DIM}▼ mais abaixo${NC}\033[K"; else printf '%b\n' "\033[K"; fi

  printf '%b\n' "\033[K"
  printf '%b\n' "  ${DIM}↑↓${NC} mover   ${DIM}→${NC} abrir   ${DIM}←${NC} fechar   ${DIM}espaço${NC} marcar\033[K"
  printf '%b\n' "  ${DIM}a${NC} tudo    ${DIM}n${NC} nada    ${DIM}ENTER${NC} instalar   ${DIM}q${NC} sair\033[K"
  printf '\033[J'
}

# ── Loop principal ─────────────────────────────────────────
tui_cleanup() { command -v tput >/dev/null 2>&1 && tput cnorm 2>/dev/null; printf '\033[?25h'; }

main_menu() {
  init_open; build_rows
  trap 'tui_cleanup; echo; exit 130' INT
  command -v tput >/dev/null 2>&1 && tput civis 2>/dev/null
  printf '\033[2J'

  local key c it
  while true; do
    tui_render
    key="$(read_key)"
    c="${ROW_CAT[$CUR]}"; it="${ROW_ITEM[$CUR]}"
    case "$key" in
      up)    CUR=$(( CUR - 1 )); [ "$CUR" -lt 0 ] && CUR=0 ;;
      down)  CUR=$(( CUR + 1 )); [ "$CUR" -ge ${#ROW_TYPE[@]} ] && CUR=$(( ${#ROW_TYPE[@]} - 1 )) ;;
      right)
        if [ "${ROW_TYPE[$CUR]}" = "c" ]; then
          if [ "${CAT_OPEN[$c]}" -eq 0 ]; then CAT_OPEN[$c]=1; build_rows
          else CUR=$(( CUR + 1 )); [ "$CUR" -ge ${#ROW_TYPE[@]} ] && CUR=$(( ${#ROW_TYPE[@]} - 1 )); fi
        fi ;;
      left)
        if [ "${ROW_TYPE[$CUR]}" = "c" ] && [ "${CAT_OPEN[$c]}" -eq 1 ]; then
          CAT_OPEN[$c]=0; build_rows
        elif [ "${ROW_TYPE[$CUR]}" = "i" ]; then
          CAT_OPEN[$c]=0; build_rows; CUR="$(row_of_cat "$c")"
        fi ;;
      space)
        if [ "${ROW_TYPE[$CUR]}" = "c" ]; then toggle_cat "$c"
        else [ "${ITEM_SEL[$it]}" -eq 1 ] && ITEM_SEL[$it]=0 || ITEM_SEL[$it]=1; fi ;;
      all)   set_all 1 ;;
      none)  set_all 0 ;;
      enter) tui_cleanup; trap - INT; printf '\033[2J\033[H'; return 0 ;;
      quit|eof) tui_cleanup; trap - INT; printf '\033[2J\033[H'; echo -e "\n  Cancelado.\n"; exit 0 ;;
    esac
  done
}

apply_only() { # apply_only "dev,browsers" — número ou parte do nome (case-insensitive)
  set_all 0
  local spec found i lname
  IFS=',' read -r -a specs <<< "$1"
  for spec in "${specs[@]}"; do
    spec="$(printf '%s' "$spec" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
    [ -z "$spec" ] && continue
    found=0; i=0
    while [ $i -lt ${#CAT_NAME[@]} ]; do
      # tira espaço dos dois lados, senão --only="dev tools" nunca casa com "Dev Tools"
      lname="$(printf '%s' "${CAT_NAME[$i]}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
      case "$spec" in
        ''|*[!0-9]*)
          case "$lname" in *"$spec"*) set_cat $i 1; found=1 ;; esac ;;
        *)
          [ "$spec" -eq $(( i + 1 )) ] && { set_cat $i 1; found=1; } ;;
      esac
      i=$(( i + 1 ))
    done
    [ "$found" -eq 0 ] && warn "--only: nenhuma categoria bate com '$spec'"
  done
}

list_cats() {
  banner
  echo -e "  ${BOLD}Categorias disponíveis:${NC}\n"
  local i=0
  while [ $i -lt ${#CAT_NAME[@]} ]; do
    count_cat $i
    echo -e "  $(pad "$(( i + 1 ))." 4)$(pad "${CAT_NAME[$i]}" 24)${DIM}$CNT_TOT item(ns)${NC}"
    i=$(( i + 1 ))
  done
  echo ""
}

# ── Execução com coleta de erros ───────────────────────────
OK_COUNT=0; SKIP_COUNT=0
FAIL_NAME=(); FAIL_MSG=()
WARN_MSG=(); NOTE_MSG=()
LAST_OUT=""

capture() { # capture <cmd...> — nunca aborta, guarda saída em LAST_OUT + log
  if [ "$DRY_RUN" -eq 1 ]; then echo -e "  ${DIM}[dry-run] $*${NC}"; LAST_OUT=""; return 0; fi
  LAST_OUT="$("$@" 2>&1)"; local rc=$?
  { echo "\$ $*"; printf '%s\n' "$LAST_OUT"; echo "--- rc=$rc"; echo ""; } >> "$LOG"
  return $rc
}

record_fail() { # record_fail <nome> <o que falhou>
  FAIL_NAME+=("$1"); FAIL_MSG+=("$2")
  fail "$1 — $2"
}

last_error_line() {
  printf '%s' "$LAST_OUT" | grep -iE 'error|fatal|denied|not found|failed' | tail -1 | cut -c1-120
}

install_brew() { # install_brew <id> <desc>
  if brew list --formula "$1" &>/dev/null; then skip "$1 (já instalado)"; SKIP_COUNT=$(( SKIP_COUNT + 1 )); return; fi
  echo -e "  ${CYAN}⏳ $1${NC}"
  if capture brew install "$1"; then ok "$1"; OK_COUNT=$(( OK_COUNT + 1 ))
  else record_fail "$1" "brew install falhou: $(last_error_line)"; fi
}

install_cask() { # install_cask <id> <desc>
  if brew list --cask "$1" &>/dev/null; then skip "$1 (já instalado)"; SKIP_COUNT=$(( SKIP_COUNT + 1 )); return; fi
  echo -e "  ${CYAN}⏳ $1${NC}"
  if capture brew install --cask --adopt "$1" || capture brew install --cask "$1"; then
    ok "$1"; OK_COUNT=$(( OK_COUNT + 1 ))
  else
    record_fail "$1" "brew install --cask falhou: $(last_error_line)"
  fi
}

step_sdkman() {
  if [ -d "$HOME/.sdkman" ]; then skip "SDKMAN (já instalado)"; SKIP_COUNT=$(( SKIP_COUNT + 1 )); return; fi
  export SDKMAN_DIR="$HOME/.sdkman"
  if capture bash -c 'curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash'; then
    ok "SDKMAN instalado"; OK_COUNT=$(( OK_COUNT + 1 ))
  else
    record_fail "sdkman" "instalação falhou: $(last_error_line)"
  fi
}

step_java17() {
  local init="$HOME/.sdkman/bin/sdkman-init.sh"
  if [ ! -s "$init" ]; then
    record_fail "java17" "SDKMAN ausente — selecione/instale SDKMAN antes"
    return
  fi
  # shellcheck disable=SC1090
  set +u; . "$init" >/dev/null 2>&1; set -u 2>/dev/null || true
  if sdk list java 2>/dev/null | grep -q '17\.0\.11-tem.*installed'; then
    skip "Java 17 (já instalado)"; SKIP_COUNT=$(( SKIP_COUNT + 1 ))
  else
    echo -e "  ${CYAN}⏳ Java 17 Temurin${NC}"
    if capture bash -c ". \"$init\" && sdk install java 17.0.11-tem"; then
      ok "Java 17 instalado"; OK_COUNT=$(( OK_COUNT + 1 ))
    else
      record_fail "java17" "sdk install falhou: $(last_error_line)"; return
    fi
  fi
  capture bash -c ". \"$init\" && sdk default java 17.0.11-tem" \
    || WARN_MSG+=("não consegui definir Java 17 como default (rode: sdk default java 17.0.11-tem)")
}

step_eascli() {
  if ! command -v npm >/dev/null 2>&1; then
    record_fail "eas-cli" "npm não encontrado — instale a categoria Languages/Runtimes (node) antes"
    return
  fi
  if command -v eas >/dev/null 2>&1; then skip "EAS CLI (já instalado)"; SKIP_COUNT=$(( SKIP_COUNT + 1 )); return; fi
  echo -e "  ${CYAN}⏳ eas-cli${NC}"
  if capture npm install -g eas-cli; then
    ok "EAS CLI instalado"; OK_COUNT=$(( OK_COUNT + 1 ))
    NOTE_MSG+=("eas login — autenticar no Expo")
  else
    record_fail "eas-cli" "npm install -g falhou: $(last_error_line)"
  fi
}

step_zshrc() {
  local src="$DOTFILES/zsh/.zshrc" dst="$HOME/.zshrc"
  if [ ! -f "$src" ]; then record_fail "zshrc" "origem não existe: $src"; return; fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "~/.zshrc (symlink já correto)"; SKIP_COUNT=$(( SKIP_COUNT + 1 )); return
  fi
  if [ -f "$dst" ] && [ ! -L "$dst" ]; then
    local backup="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    if cp "$dst" "$backup"; then warn "backup do .zshrc antigo em $backup"
    else record_fail "zshrc" "não consegui fazer backup de $dst"; return; fi
  fi
  if capture ln -sfn "$src" "$dst"; then
    ok "~/.zshrc → dotfiles/zsh/.zshrc"; OK_COUNT=$(( OK_COUNT + 1 ))
    NOTE_MSG+=("source ~/.zshrc — recarregar o shell")
  else
    record_fail "zshrc" "symlink falhou: $(last_error_line)"
  fi
}

step_xcode() {
  if [ ! -d "/Applications/Xcode.app" ]; then
    record_fail "xcode" "Xcode.app não instalado — instale pela App Store: mas install 497799835"
    return
  fi
  capture sudo xcode-select -s /Applications/Xcode.app/Contents/Developer \
    || WARN_MSG+=("xcode-select falhou (rode manualmente com sudo)")
  capture sudo xcodebuild -license accept \
    || WARN_MSG+=("licença do Xcode não aceita (rode: sudo xcodebuild -license accept)")
  ok "Xcode: $(xcodebuild -version 2>/dev/null | head -1)"
  OK_COUNT=$(( OK_COUNT + 1 ))
}

# ── sudo: pedir uma vez, com contexto ──────────────────────
# Casks com artefato `binary` criam symlinks em /usr/local/bin, que é
# root:wheel no Apple Silicon (o brew mora em /opt/homebrew). Sem isso o
# sudo dispara no meio da instalação: o prompt escapa do $(...) da
# capture() via /dev/tty e aparece como um "Password:" pelado, sem dizer
# quem pediu. E o timestamp do sudo expira em 5 min, então ele repergunta.
SUDO_PID=""

needs_sudo() {
  local i=0
  while [ $i -lt ${#ITEM_ID[@]} ]; do
    if [ "${ITEM_SEL[$i]}" -eq 1 ]; then
      [ "${ITEM_TYPE[$i]}" = "cask" ] && return 0
      [ "${ITEM_ID[$i]}" = "xcode" ]  && return 0
    fi
    i=$(( i + 1 ))
  done
  return 1
}

sudo_keepalive() {
  # $$ dentro do subshell continua sendo o PID do script, não do subshell
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
  SUDO_PID=$!
  disown 2>/dev/null || true   # senão o shell imprime "Terminated: 15" ao matar
}

sudo_stop() { [ -n "$SUDO_PID" ] && kill "$SUDO_PID" 2>/dev/null; SUDO_PID=""; }

sudo_prewarm() {
  [ "$DRY_RUN" -eq 1 ] && return 0
  needs_sudo || return 0

  log "Permissão de administrador"
  if sudo -n true 2>/dev/null; then
    ok "sudo já autorizado nesta sessão"
    sudo_keepalive
    return 0
  fi

  echo "  Alguns apps (Docker e outros) criam symlinks em /usr/local/bin,"
  echo "  que pertence ao root. O Xcode também precisa."
  echo "  Digite sua senha do macOS uma vez agora — assim a instalação não"
  echo "  para no meio pedindo senha sem contexto."
  echo ""
  # sem capture(): o prompt do sudo precisa chegar no terminal
  if sudo -v; then
    ok "autorizado"
    sudo_keepalive
    return 0
  fi
  WARN_MSG+=("sudo não autorizado — apps que precisam de root podem falhar ou pedir senha no meio")
  return 1
}

ensure_homebrew() {
  log "Homebrew"
  if command -v brew >/dev/null 2>&1; then ok "$(brew --version | head -1)"; return 0; fi
  if [ "$DRY_RUN" -eq 1 ]; then echo -e "  ${DIM}[dry-run] instalaria Homebrew${NC}"; return 0; fi
  echo "  Instalando Homebrew..."
  if capture bash -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; then
    [ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew instalado"; return 0
  fi
  record_fail "homebrew" "instalação falhou — nada que dependa de brew vai rodar"
  return 1
}

install_taps() {
  [ ${#TAPS[@]} -eq 0 ] && return
  log "Taps"
  local t
  for t in "${TAPS[@]}"; do
    [ -z "$t" ] && continue
    if brew tap | grep -qx "$t"; then skip "$t"; continue; fi
    capture brew tap "$t" && ok "$t" || record_fail "tap $t" "brew tap falhou: $(last_error_line)"
  done
}

run_install() {
  local i=0 c=-1 has_brew=1 selected=0

  while [ $i -lt ${#ITEM_SEL[@]} ]; do
    [ "${ITEM_SEL[$i]}" -eq 1 ] && selected=$(( selected + 1 ))
    i=$(( i + 1 ))
  done
  if [ "$selected" -eq 0 ]; then echo -e "\n  Nada selecionado. Saindo.\n"; exit 0; fi

  clear; banner
  echo -e "  ${DIM}Log completo: $LOG${NC}"
  [ "$DRY_RUN" -eq 1 ] && echo -e "  ${YELLOW}MODO DRY-RUN — nada será instalado${NC}"
  echo "dotfiles install — $(date)" > "$LOG"

  trap 'sudo_stop' EXIT
  sudo_prewarm

  # brew só é necessário se houver item brew/cask selecionado
  i=0
  local needs_brew=0
  while [ $i -lt ${#ITEM_ID[@]} ]; do
    if [ "${ITEM_SEL[$i]}" -eq 1 ]; then
      case "${ITEM_TYPE[$i]}" in brew|cask) needs_brew=1 ;; esac
    fi
    i=$(( i + 1 ))
  done
  if [ "$needs_brew" -eq 1 ]; then
    ensure_homebrew || has_brew=0
    [ "$has_brew" -eq 1 ] && install_taps
  fi

  i=0
  while [ $i -lt ${#ITEM_ID[@]} ]; do
    if [ "${ITEM_SEL[$i]}" -eq 1 ]; then
      if [ "${ITEM_CAT[$i]}" -ne "$c" ]; then
        c="${ITEM_CAT[$i]}"; log "${CAT_NAME[$c]}"
      fi
      case "${ITEM_TYPE[$i]}" in
        brew) if [ "$has_brew" -eq 1 ]; then install_brew "${ITEM_ID[$i]}"
              else record_fail "${ITEM_ID[$i]}" "pulado: Homebrew indisponível"; fi ;;
        cask) if [ "$has_brew" -eq 1 ]; then install_cask "${ITEM_ID[$i]}"
              else record_fail "${ITEM_ID[$i]}" "pulado: Homebrew indisponível"; fi ;;
        step)
          if [ "$DRY_RUN" -eq 1 ]; then echo -e "  ${DIM}[dry-run] etapa: ${ITEM_ID[$i]}${NC}"
          else
            case "${ITEM_ID[$i]}" in
              sdkman) step_sdkman ;; java17) step_java17 ;; eascli) step_eascli ;;
              zshrc)  step_zshrc  ;; xcode)  step_xcode  ;;
            esac
          fi
          ;;
      esac
      [ "${ITEM_ID[$i]}" = "android-studio" ] && \
        NOTE_MSG+=("Android Studio → SDK Manager → instalar Android SDK API 34")
    fi
    i=$(( i + 1 ))
  done
}

final_report() {
  echo ""
  divider
  echo ""
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${BOLD}${YELLOW}Dry-run concluído — nada foi instalado.${NC}\n"
    return 0
  fi

  echo -e "  ${BOLD}RESUMO${NC}\n"
  echo -e "    ${GREEN}✅ instalados:${NC}   $OK_COUNT"
  echo -e "    ${DIM}⏭  já presentes:${NC} $SKIP_COUNT"
  echo -e "    ${YELLOW}⚠️  avisos:${NC}      ${#WARN_MSG[@]}"
  echo -e "    ${RED}❌ falhas:${NC}      ${#FAIL_NAME[@]}"

  if [ ${#WARN_MSG[@]} -gt 0 ]; then
    echo -e "\n  ${BOLD}${YELLOW}Avisos${NC}"
    local w; for w in "${WARN_MSG[@]}"; do echo -e "    ${YELLOW}⚠️${NC}  $w"; done
  fi

  if [ ${#FAIL_NAME[@]} -gt 0 ]; then
    echo -e "\n  ${BOLD}${RED}Falhas — o resto foi configurado normalmente${NC}"
    local i=0
    while [ $i -lt ${#FAIL_NAME[@]} ]; do
      echo -e "    ${RED}❌ ${FAIL_NAME[$i]}${NC}"
      echo -e "       ${DIM}${FAIL_MSG[$i]}${NC}"
      i=$(( i + 1 ))
    done
    echo -e "\n    ${DIM}Log completo: $LOG${NC}"
    echo -e "    ${DIM}Reinstalar só o que falhou: bash scripts/install.sh (marque só esses itens)${NC}"
  fi

  if [ ${#NOTE_MSG[@]} -gt 0 ]; then
    echo -e "\n  ${BOLD}Próximos passos${NC}"
    local n; for n in "${NOTE_MSG[@]}"; do echo -e "    ${BLUE}→${NC} $n"; done
  fi

  echo ""
  if [ ${#FAIL_NAME[@]} -gt 0 ]; then
    echo -e "  ${BOLD}${YELLOW}Setup concluído com ${#FAIL_NAME[@]} falha(s).${NC}"
  else
    echo -e "  ${BOLD}${GREEN}Setup concluído! 🎉${NC}"
  fi
  echo ""
  divider
  [ ${#FAIL_NAME[@]} -gt 0 ] && return 1
  return 0
}

# ── Main ───────────────────────────────────────────────────
case "$MODE" in
  help) show_help; exit 0 ;;
esac

build_catalog

case "$MODE" in
  list) list_cats; exit 0 ;;
  all)  ;;                      # tudo já vem marcado por padrão
  only) apply_only "$ONLY" ;;
  menu) main_menu ;;
esac

run_install
final_report
