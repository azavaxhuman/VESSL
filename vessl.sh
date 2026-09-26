#!/bin/bash

VERSION="2.0.2"
APP_TAGLINE="Very Easy SSL"
REPO_URL="https://github.com/azavaxhuman/VESSL"
RAW_URL="https://raw.githubusercontent.com/azavaxhuman/VESSL/main/vessl.sh"
UPSTREAM_NAME="ESSL by erfjab"
UPSTREAM_URL="https://github.com/erfjab/ESSL"
YOUTUBE_URL="https://www.youtube.com/@Dailydigitalskills"
YOUTUBE_NAME="Daily Digital Skills"
INSTALL_PATH="/usr/local/bin/vessl"
CONFIG_DIR="/etc/vessl"
CONFIG_FILE="$CONFIG_DIR/config"
REGISTRY_FILE="$CONFIG_DIR/certs.db"
LOG_FILE="/var/log/vessl.log"
ACME_HOME="$HOME/.acme.sh"
ACME="$ACME_HOME/acme.sh"
LE_DIRECTORY="https://acme-v02.api.letsencrypt.org/directory"
CF_API="https://api.cloudflare.com/client/v4"
CF_TOKEN_PAGE="https://dash.cloudflare.com/profile/api-tokens"
PANELS=(marzban marzneshin pasarguard rebecca x-ui 3x-ui s-ui hiddify ovpanel)
SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
TXT_WAIT_SECONDS=600
MENU_NOTICE=""

email=""
destination=""
DEST_TARGET=""
DOMAINS=()
WILDCARD=0
DNS_METHOD=""
CF_TOKEN_IN=""
CF_KEY_IN=""
CF_EMAIL_IN=""
ASSUME_YES=0
PURGE=0
RUN_TEST=0
SKIP_CHECK=0
FORCE=0
VERBOSE=0
CLI_VERBOSE=0
CONFIG_VERBOSE=0
IS_TTY=0
BOX_W=60
DEFAULT_EMAIL=""
DEFAULT_DEST=""
SERVER_IPV4=""
SERVER_IPV6=""
LOCAL_IPS=""
IPS_DONE=0
ZONE_NAME=""
ZONE_NS=""
PREFLIGHT_ERRORS=0
PREFLIGHT_WARNINGS=0
PORT80_STATE=""
PORT_OWNERS=()
STOPPED_SERVICES=()
STOPPED_CONTAINERS=()
HOOKS=()
STEP_CUR=0
STEP_TOTAL=1
ENGINE=""
TASK_PID=""
LAST_OUTPUT=""
CERT_DIRS=()
SEL_DIR=""
TXT_NAMES=()
TXT_VALUES=()
HAS_ACME=0
HAS_CERTBOT=0
C_DAYS=0
C_TOTAL=90
C_END_DATE=""

setup_locale() {
    local loc
    if ! locale charmap 2>/dev/null | grep -qi 'utf-\?8'; then
        loc=$(locale -a 2>/dev/null | grep -iE '^(c|en_us)\.utf-?8$' | head -n1)
        [ -n "$loc" ] && export LC_ALL="$loc"
    fi
}

setup_colors() {
    if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
        IS_TTY=1
        reset=$'\033[0m'
        bold=$'\033[1m'
        red=$'\033[38;5;203m'
        green=$'\033[38;5;84m'
        orange=$'\033[38;5;214m'
        cyan=$'\033[38;5;51m'
        blue=$'\033[38;5;75m'
        purple=$'\033[38;5;141m'
        gray=$'\033[38;5;245m'
        yellow=$'\033[38;5;220m'
        ytred=$'\033[38;5;196m'
        GRAD=($'\033[38;5;51m' $'\033[38;5;45m' $'\033[38;5;39m' $'\033[38;5;33m' $'\033[38;5;63m' $'\033[38;5;99m')
    else
        IS_TTY=0
        reset="" bold="" yellow="" ytred="" red="" green="" orange="" cyan="" blue="" purple="" gray=""
        GRAD=("" "" "" "" "" "")
    fi
    update_width
}

update_width() {
    local cols
    cols=$(tput cols 2>/dev/null)
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
    BOX_W=$((cols - 4))
    ((BOX_W > 76)) && BOX_W=76
    ((BOX_W < 44)) && BOX_W=44
}

setup_log() {
    if ! touch "$LOG_FILE" 2>/dev/null; then
        LOG_FILE="${TMPDIR:-/tmp}/vessl.log"
    fi
}

print() { printf '%s\n' "${cyan}$1${reset}"; }
error() { printf '  %s\n' "${red}✗ $1${reset}"; }
success() { printf '  %s\n' "${green}✓${reset} $1"; }
log() { printf '  %s\n' "${blue}›${reset} $1"; }
warn() { printf '  %s\n' "${orange}⚠ $1${reset}"; }
hint() { printf '    %s\n' "${gray}$1${reset}"; }
section() { printf '\n  %s\n' "${purple}${bold}▌ $1${reset}"; }
sub() { printf '\n  %s\n' "${purple}$1${reset}"; }

rep() {
    local s="" i
    for ((i = 0; i < $2; i++)); do s+="$1"; done
    printf '%s' "$s"
}

vlen() {
    local s
    s=$(sed 's/\x1b\[[0-9;]*m//g' <<< "$1")
    printf '%s' "${#s}"
}

col() {
    local n
    n=$(($2 - $(vlen "$1")))
    ((n < 1)) && n=1
    printf '%s%s' "$1" "$(rep ' ' "$n")"
}

fit() {
    local s=$1 max=$2
    if ((${#s} > max)); then
        s="…${s: -$((max - 1))}"
    fi
    printf '%s' "$s"
}

box_top() {
    local title=" $1 " fill
    fill=$((BOX_W - 3 - $(vlen "$title")))
    printf '  %s╭─%s%s%s%s╮%s\n' "$gray" "$reset$bold" "$title" "$reset$gray" "$(rep ─ "$fill")" "$reset"
}

box_row() {
    local pad
    pad=$((BOX_W - 4 - $(vlen "$1")))
    ((pad < 0)) && pad=0
    printf '  %s│%s %s%s %s│%s\n' "$gray" "$reset" "$1" "$(rep ' ' "$pad")" "$gray" "$reset"
}

box_kv() {
    box_row "$(col "${gray}$1${reset}" 13)$(fit "$2" $((BOX_W - 18)))"
}

box_bottom() {
    printf '  %s╰%s╯%s\n' "$gray" "$(rep ─ $((BOX_W - 2)))" "$reset"
}

banner() {
    local i art=(
        "██╗   ██╗███████╗███████╗███████╗██╗     "
        "██║   ██║██╔════╝██╔════╝██╔════╝██║     "
        "██║   ██║█████╗  ███████╗███████╗██║     "
        "╚██╗ ██╔╝██╔══╝  ╚════██║╚════██║██║     "
        " ╚████╔╝ ███████╗███████║███████║███████╗"
        "  ╚═══╝  ╚══════╝╚══════╝╚══════╝╚══════╝"
    )
    printf '\n'
    if ((BOX_W >= 46)); then
        for i in "${!art[@]}"; do
            printf '  %s%s%s\n' "${GRAD[$i]}" "${art[$i]}" "$reset"
        done
    else
        printf '  %s\n' "${cyan}${bold}V E S S L${reset}"
    fi
    printf '  %s  %s\n' "${bold}${APP_TAGLINE}${reset}" "${gray}v${VERSION}${reset}"
    printf '  %s\n\n' "${gray}forked from ${UPSTREAM_NAME}${reset}"
}

support_box() {
    local gh=${REPO_URL#https://} yt=${YOUTUBE_URL#https://www.}
    box_top "Enjoying VESSL?"
    box_row "$(col "${yellow}★${reset} ${bold}Star it on GitHub${reset}" 26)${cyan}$gh${reset}"
    box_row "$(col "${ytred}▶${reset} ${bold}Subscribe on YouTube${reset}" 26)${cyan}$yt${reset}"
    box_row "${gray}It is free, and it keeps new features and video guides coming.${reset}"
    box_bottom
}

support_line() {
    printf '  %s%s\n' "$(col "${yellow}★${reset} ${gray}Star on GitHub${reset}" 25)" "${cyan}${REPO_URL#https://}${reset}"
    printf '  %s%s\n' "$(col "${ytred}▶${reset} ${gray}Subscribe on YouTube${reset}" 25)" "${cyan}${YOUTUBE_URL#https://www.}${reset}"
}

hide_cursor() {
    if [ "$IS_TTY" -eq 1 ]; then printf '\033[?25l'; fi
}

show_cursor() {
    if [ "$IS_TTY" -eq 1 ]; then printf '\033[?25h'; fi
}

clear_screen() {
    if [ "$IS_TTY" -eq 1 ]; then printf '\033[H\033[2J\033[3J'; fi
}

restore_services() {
    local s c
    for s in "${STOPPED_SERVICES[@]}"; do
        if systemctl start "$s"; then
            success "Service $s started again"
        else
            error "Failed to start $s, start it manually: systemctl start $s"
        fi
    done
    for c in "${STOPPED_CONTAINERS[@]}"; do
        if docker start "$c" >/dev/null; then
            success "Container $c started again"
        else
            error "Failed to start container $c, start it manually: docker start $c"
        fi
    done
    STOPPED_SERVICES=()
    STOPPED_CONTAINERS=()
}

clear_secrets() {
    CF_TOKEN_IN=""
    CF_KEY_IN=""
    CF_EMAIL_IN=""
}

kill_tree() {
    local c
    for c in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$c"; done
    kill "$1" 2>/dev/null
}

on_interrupt() {
    show_cursor
    printf '\n'
    if [ -n "$TASK_PID" ]; then
        kill_tree "$TASK_PID"
        TASK_PID=""
        error "Interrupted"
    else
        printf '  %s\n\n' "${gray}Bye.${reset}"
    fi
    exit 130
}

on_exit() {
    show_cursor
    restore_services
    clear_secrets
    [ -n "$LAST_OUTPUT" ] && rm -f "$LAST_OUTPUT"
}

trap on_interrupt INT TERM
trap on_exit EXIT

run_task() {
    local quiet=0 label out rc start el i=0
    if [ "$1" = "-q" ]; then
        quiet=1
        shift
    fi
    label=$1
    shift
    [ -n "$LAST_OUTPUT" ] && rm -f "$LAST_OUTPUT"
    out=$(mktemp)
    LAST_OUTPUT=$out
    start=$SECONDS
    printf '\n=== %s | %s ===\n' "$(date '+%F %T')" "$label" >>"$LOG_FILE" 2>/dev/null
    if [ "$VERBOSE" -eq 1 ] || [ "$IS_TTY" -eq 0 ]; then
        log "$label"
        "$@" 2>&1 | tee "$out"
        rc=${PIPESTATUS[0]}
    else
        hide_cursor
        "$@" >"$out" 2>&1 &
        TASK_PID=$!
        while kill -0 "$TASK_PID" 2>/dev/null; do
            printf '\r  %s %s %s' "${cyan}${SPIN[i % ${#SPIN[@]}]}${reset}" "$label" "${gray}$((SECONDS - start))s${reset}"
            i=$((i + 1))
            sleep 0.1
        done
        wait "$TASK_PID"
        rc=$?
        TASK_PID=""
        printf '\r\033[K'
        show_cursor
    fi
    cat "$out" >>"$LOG_FILE" 2>/dev/null
    el=$((SECONDS - start))
    if [ "$rc" -eq 0 ]; then
        [ "$quiet" -eq 1 ] || success "$label ${gray}${el}s${reset}"
    else
        error "$label ${gray}exit $rc · ${el}s${reset}"
    fi
    return "$rc"
}

step() {
    local w=26 f pct
    STEP_CUR=$((STEP_CUR + 1))
    pct=$(((STEP_CUR - 1) * 100 / STEP_TOTAL))
    f=$(((STEP_CUR - 1) * w / STEP_TOTAL))
    printf '\n  %s  %s%s  %s  %s\n' \
        "${purple}${bold}Step ${STEP_CUR}/${STEP_TOTAL}${reset}" \
        "${cyan}$(rep ━ "$f")" "${gray}$(rep ─ $((w - f)))${reset}" \
        "${gray}$(printf '%3d%%' "$pct")${reset}" "${bold}$1${reset}"
}

steps_done() {
    printf '\n  %s  %s  %s  %s\n' "${green}${bold}Finished${reset}" "${green}$(rep ━ 26)${reset}" "${gray}100%${reset}" "${bold}$1${reset}"
}

confirm() {
    local a
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -t 0 ] || return 1
    read -r -p "  ${orange}?${reset} $1 ${gray}[y/N]${reset} " a || return 1
    [[ "$a" =~ ^[Yy]([Ee][Ss])?$ ]]
}

confirm_optional() {
    local a
    [ "$PURGE" -eq 1 ] && return 0
    [ "$ASSUME_YES" -eq 1 ] && return 1
    [ -t 0 ] || return 1
    read -r -p "  ${orange}?${reset} $1 ${gray}[y/N]${reset} " a || return 1
    [[ "$a" =~ ^[Yy]([Ee][Ss])?$ ]]
}

ask_continue() {
    local a
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -t 0 ] || return 0
    read -r -p "  ${orange}?${reset} $1 ${gray}[Y/n]${reset} " a || return 1
    [[ ! "$a" =~ ^[Nn]([Oo])?$ ]]
}

ask() {
    local v
    read -r -p "  ${cyan}❯${reset} $1${2:+ ${gray}[$2]${reset}}: " v || return 1
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "${v:-$2}"
}

ask_secret() {
    local v
    read -r -s -p "  ${cyan}❯${reset} $1 ${gray}(hidden)${reset}: " v || return 1
    printf '\n' >&2
    v="${v//[[:space:]]/}"
    printf '%s' "$v"
}

pause() {
    [ -t 0 ] || return 0
    printf '\n'
    read -r -s -p "  ${gray}Press Enter to go back to the menu${reset}" _ || exit 0
    printf '\n'
}

require_root() {
    [ "$EUID" -eq 0 ] || {
        error "VESSL must be run as root."
        exit 1
    }
}

clean_domain() {
    local d="$1"
    d="${d//\"/}"
    d="${d//\'/}"
    d="${d%.}"
    printf '%s' "${d,,}"
}

validate_domain() {
    local d=$1
    if [[ "$d" == \** ]]; then
        if [ "$WILDCARD" -ne 1 ]; then
            error "Wildcard domains need DNS validation: $d"
            hint "Use menu option [2] or: vessl --wildcard <email> <domain> <destination>"
            return 1
        fi
        d=${d#\*.}
    fi
    if [[ ! "$d" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+([a-z]{2,}|xn--[a-z0-9-]+)$ ]]; then
        error "Invalid domain format: $1"
        return 1
    fi
    return 0
}

validate_email() {
    if [[ ! "$1" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
        error "Invalid email format: $1"
        return 1
    fi
    return 0
}

prepare_domains() {
    local d
    DOMAINS=()
    for d in "$@"; do
        [ -n "$d" ] || continue
        d=$(clean_domain "$d")
        validate_domain "$d" || return 1
        [[ " ${DOMAINS[*]} " == *" $d "* ]] || DOMAINS+=("$d")
    done
    if [ ${#DOMAINS[@]} -eq 0 ]; then
        error "No domain provided."
        return 1
    fi
}

prepare_wildcard() {
    local d
    d=$(clean_domain "$1")
    d=${d#\*.}
    WILDCARD=1
    validate_domain "$d" || return 1
    DOMAINS=("$d" "*.$d")
}

has_wildcard() {
    local d
    for d in "$@"; do
        [[ "$d" == \** ]] && return 0
    done
    return 1
}

panel_base() {
    case "$1" in
        marzban) echo "/var/lib/marzban/certs" ;;
        marzneshin) echo "/var/lib/marzneshin/certs" ;;
        pasarguard) echo "/var/lib/pasarguard/certs" ;;
        rebecca) echo "/var/lib/rebecca/certs" ;;
        x-ui|3x-ui|s-ui|hiddify) echo "/certs" ;;
        ovpanel) echo "/opt/ov-panel/data" ;;
        *) return 1 ;;
    esac
}

panel_title() {
    case "$1" in
        marzban) echo "Marzban" ;;
        marzneshin) echo "Marzneshin" ;;
        pasarguard) echo "PasarGuard" ;;
        rebecca) echo "Rebecca" ;;
        x-ui) echo "X-UI" ;;
        3x-ui) echo "3X-UI" ;;
        s-ui) echo "S-UI" ;;
        hiddify) echo "Hiddify" ;;
        ovpanel) echo "OV-Panel" ;;
        *) echo "$1" ;;
    esac
}

dns_method_title() {
    case "$1" in
        cf_saved) echo "Cloudflare DNS, saved credentials" ;;
        cf_token) echo "Cloudflare DNS, API token" ;;
        cf_key) echo "Cloudflare DNS, Global API Key" ;;
        manual) echo "Manual DNS TXT records" ;;
        *) echo "HTTP on port 80" ;;
    esac
}

method_family() {
    case "$1" in
        cf_*) echo "dns_cf" ;;
        manual) echo "dns_manual" ;;
        *) echo "http" ;;
    esac
}

norm_path() {
    local p=$1
    [[ "$p" == "~"* ]] && p="$HOME${p:1}"
    p=$(tr -s '/' <<< "$p")
    while [ "${#p}" -gt 1 ] && [[ "$p" == */ ]]; do p="${p%/}"; done
    printf '%s' "$p"
}

is_custom_path() {
    [[ "$1" == /* || "$1" == "~"* ]]
}

dest_text() {
    if panel_base "$1" >/dev/null; then
        printf '%s %s' "$(panel_title "$1")" "${gray}$(panel_base "$1")/${reset}"
    elif [ -n "$1" ]; then
        printf '%s' "$1/"
    else
        printf '%s' "${gray}not set${reset}"
    fi
}

resolve_destination() {
    local base
    if base=$(panel_base "$1"); then
        DEST_TARGET=$1
    elif is_custom_path "$1"; then
        DEST_TARGET=$(norm_path "$1")
        base=$DEST_TARGET
        [ "$base" = "/" ] && base=""
    else
        error "Invalid destination: $1"
        hint "Use a panel name or an absolute path that starts with '/'."
        hint "A trailing slash is optional: /root/certs and /root/certs/ are the same."
        return 1
    fi
    destination="${base}/${DOMAINS[0]}/"
}

load_config() {
    local k v
    [ -r "$CONFIG_FILE" ] || return 0
    while IFS='=' read -r k v; do
        case "$k" in
            DEFAULT_EMAIL) DEFAULT_EMAIL=$v ;;
            DEFAULT_DEST) DEFAULT_DEST=$v ;;
            VERBOSE) CONFIG_VERBOSE=$v ;;
        esac
    done < "$CONFIG_FILE"
    [ "$CONFIG_VERBOSE" = "1" ] && VERBOSE=1
}

save_config() {
    mkdir -p "$CONFIG_DIR" 2>/dev/null || return 1
    printf 'DEFAULT_EMAIL=%s\nDEFAULT_DEST=%s\nVERBOSE=%s\n' "$DEFAULT_EMAIL" "$DEFAULT_DEST" "$CONFIG_VERBOSE" > "$CONFIG_FILE"
}

reg_save() {
    local tmp
    mkdir -p "$CONFIG_DIR" 2>/dev/null || return 1
    touch "$REGISTRY_FILE"
    tmp=$(mktemp)
    awk -F'|' -v d="$3" '$3 != d' "$REGISTRY_FILE" > "$tmp"
    printf '%s|%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >> "$tmp"
    mv "$tmp" "$REGISTRY_FILE"
}

reg_get() {
    [ -r "$REGISTRY_FILE" ] || return 1
    awk -F'|' -v d="$1" '$3 == d {print; exit}' "$REGISTRY_FILE"
}

reg_field() {
    reg_get "$1" | cut -d'|' -f"$2"
}

reg_del() {
    local tmp
    [ -f "$REGISTRY_FILE" ] || return 0
    tmp=$(mktemp)
    awk -F'|' -v d="$1" '$3 != d' "$REGISTRY_FILE" > "$tmp"
    mv "$tmp" "$REGISTRY_FILE"
}

_install_packages() {
    local pm=$1 refresh=$2 rc=0 p
    shift 2
    $refresh
    for p in "$@"; do
        $pm install -y "$p" || rc=1
    done
    return $rc
}

_install_acme() {
    curl -fsSL https://get.acme.sh | sh -s ${email:+email="$email"}
    [ -x "$ACME" ]
}

install_dependencies() {
    local pm="" refresh="" cmd
    local -A wanted=([curl]=curl [socat]=socat [certbot]=certbot [openssl]=openssl)
    local missing=()

    if command -v apt-get &>/dev/null; then
        pm="apt-get"
        refresh="apt-get update -y"
        export DEBIAN_FRONTEND=noninteractive
        wanted[ss]=iproute2
        wanted[crontab]=cron
        wanted[dig]=dnsutils
    elif command -v dnf &>/dev/null; then
        pm="dnf"
        refresh="dnf makecache -y"
        wanted[ss]=iproute
        wanted[crontab]=cronie
        wanted[dig]=bind-utils
    elif command -v yum &>/dev/null; then
        pm="yum"
        refresh="yum makecache -y"
        wanted[ss]=iproute
        wanted[crontab]=cronie
        wanted[dig]=bind-utils
    fi

    for cmd in "${!wanted[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("${wanted[$cmd]}")
    done

    if [ ${#missing[@]} -eq 0 ]; then
        success "System packages are ready"
    elif [ -z "$pm" ]; then
        warn "Missing ${missing[*]} and no supported package manager was found"
    else
        run_task "Installing ${missing[*]}" _install_packages "$pm" "$refresh" "${missing[@]}" || warn "Some packages could not be installed"
    fi

    if [ -x "$ACME" ]; then
        success "acme.sh is ready"
    else
        run_task "Installing acme.sh" _install_acme || warn "acme.sh could not be installed"
    fi
}

have_socket_tool() {
    command -v ss &>/dev/null || command -v netstat &>/dev/null
}

collect_listeners() {
    local laddr rest port addr proc pid
    if command -v ss &>/dev/null; then
        ss -H -ltnp 2>/dev/null | while read -r _ _ _ laddr _ rest; do
            port="${laddr##*:}"
            [[ "$port" =~ ^[0-9]+$ ]] || continue
            addr="${laddr%:*}"
            proc=$(sed -n 's/.*users:(("\([^"]*\)".*/\1/p' <<< "$rest")
            pid=$(sed -n 's/^[^=]*pid=\([0-9]*\).*/\1/p' <<< "$rest")
            echo "${port}|${addr}|${proc:--}|${pid:--}"
        done
    elif command -v netstat &>/dev/null; then
        netstat -ltnp 2>/dev/null | awk 'NR>2 {
            n = split($4, a, ":"); port = a[n];
            addr = substr($4, 1, length($4) - length(port) - 1);
            split($7, b, "/"); pid = b[1]; proc = b[2];
            if (pid == "") pid = "-"; if (proc == "") proc = "-";
            print port "|" addr "|" proc "|" pid
        }'
    else
        return 1
    fi
}

port_users() {
    collect_listeners 2>/dev/null | awk -F'|' -v p="$1" '$1 == p {print $3}' | sort -u | paste -sd, -
}

unit_of_pid() {
    local pid=$1 unit
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    unit=$(ps -o unit= -p "$pid" 2>/dev/null | awk '{print $1}')
    if [[ "$unit" != *.service ]] && [ -r "/proc/$pid/cgroup" ]; then
        unit=$(grep -o '[^/]*\.service' "/proc/$pid/cgroup" 2>/dev/null | tail -n1)
    fi
    case "$unit" in
        docker.service|containerd.service|"") return 1 ;;
        *.service) echo "$unit" ;;
        *) return 1 ;;
    esac
}

container_of_pid() {
    local pid=$1 cid
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    [ -r "/proc/$pid/cgroup" ] || return 1
    command -v docker &>/dev/null || return 1
    cid=$(grep -oE '[0-9a-f]{64}' "/proc/$pid/cgroup" 2>/dev/null | head -n1)
    [ -n "$cid" ] || return 1
    docker inspect --format '{{.Name}}' "$cid" 2>/dev/null | sed 's#^/##'
}

container_of_port() {
    command -v docker &>/dev/null || return 1
    docker ps --format '{{.Names}}|{{.Ports}}' 2>/dev/null | awk -F'|' -v p=":$1->" 'index($2, p) {print $1; exit}'
}

owner_label() {
    local proc=$1 pid=$2 port=$3 name
    if [ "$proc" = "docker-proxy" ]; then
        name=$(container_of_port "$port")
        if [ -n "$name" ]; then
            echo "container:$name"
            return
        fi
    fi
    name=$(container_of_pid "$pid")
    if [ -n "$name" ]; then
        echo "container:$name"
        return
    fi
    name=$(unit_of_pid "$pid")
    if [ -n "$name" ]; then
        echo "service:$name"
        return
    fi
    echo "-"
}

check_port() {
    local port=$1 mode=$2 lines addr proc pid label
    PORT_OWNERS=()
    if ! have_socket_tool; then
        warn "Neither ss nor netstat is available, cannot check port $port"
        return 2
    fi
    lines=$(collect_listeners | awk -F'|' -v p="$port" '$1 == p' | sort -u)
    if [ -z "$lines" ]; then
        success "Port $port is free"
        return 0
    fi
    if [ "$mode" = "info" ]; then
        log "Port $port is used by:"
    else
        warn "Port $port is in use:"
    fi
    while IFS='|' read -r _ addr proc pid; do
        label=$(owner_label "$proc" "$pid" "$port")
        hint "$addr → $proc (pid $pid) [$label]"
        PORT_OWNERS+=("$label")
    done <<< "$lines"
    return 1
}

show_ports() {
    local lines port addr proc pid label c
    section "Listening TCP ports"
    printf '\n'
    if ! have_socket_tool; then
        error "Neither ss nor netstat is available"
        return 1
    fi
    lines=$(collect_listeners | sort -t'|' -k1,1n -k2,2 -u)
    if [ -z "$lines" ]; then
        warn "No listening TCP ports found"
        return 0
    fi
    printf '  %s\n' "${bold}$(printf '%-7s %-26s %-18s %-9s %s' PORT ADDRESS PROCESS PID OWNER)${reset}"
    printf '  %s\n' "${gray}$(rep ─ $((BOX_W - 2)))${reset}"
    while IFS='|' read -r port addr proc pid; do
        label=$(owner_label "$proc" "$pid" "$port")
        c=""
        if [ "$port" = "80" ] || [ "$port" = "443" ]; then c=$orange; fi
        printf '  %s%-7s%s %-26s %-18s %-9s %s\n' "$c$bold" "$port" "$reset$c" "$addr" "$proc" "$pid" "${gray}$label${reset}"
    done <<< "$lines"
    printf '\n'
    if [ -n "$(port_users 80)" ]; then
        hint "Port 80 is needed for HTTP validation. VESSL can stop its owner for a few seconds while issuing."
        hint "Wildcard certificates use DNS validation and do not need port 80."
    fi
    [ "$EUID" -eq 0 ] || warn "Run as root to see process names and owners"
}

free_port() {
    local port=$1 label owners=()
    if [ -z "$PORT80_STATE" ]; then
        check_port "$port"
        case $? in
            0) PORT80_STATE="free" ;;
            1) PORT80_STATE="busy" ;;
            *) PORT80_STATE="unknown" ;;
        esac
    elif [ "$PORT80_STATE" = "free" ]; then
        success "Port $port is free"
    fi
    [ "$PORT80_STATE" = "busy" ] || return 0

    mapfile -t owners < <(printf '%s\n' "${PORT_OWNERS[@]}" | sort -u)
    for label in "${owners[@]}"; do
        if [[ "$label" != service:* && "$label" != container:* ]]; then
            error "Port $port is held by a process that is not a systemd service or a docker container."
            hint "Stop it manually and try again. Run 'vessl --ports' to see it."
            return 1
        fi
    done

    hint "Whatever runs on port $port will be down for a few seconds."
    if ! confirm "Stop ${owners[*]} temporarily and start it again afterwards?"; then
        error "Port $port must be free for HTTP validation."
        return 1
    fi

    for label in "${owners[@]}"; do
        case "$label" in
            service:*)
                if systemctl stop "${label#service:}"; then
                    STOPPED_SERVICES+=("${label#service:}")
                    log "Stopped ${label#service:}"
                else
                    error "Failed to stop ${label#service:}"
                    return 1
                fi
                ;;
            container:*)
                if docker stop "${label#container:}" >/dev/null; then
                    STOPPED_CONTAINERS+=("${label#container:}")
                    log "Stopped container ${label#container:}"
                else
                    error "Failed to stop container ${label#container:}"
                    return 1
                fi
                ;;
        esac
    done

    sleep 2
    if check_port "$port"; then
        PORT80_STATE="free"
        return 0
    fi
    error "Port $port is still in use."
    return 1
}

build_hooks() {
    local pre="" post="" s c
    HOOKS=()
    for s in "${STOPPED_SERVICES[@]}"; do
        pre+="systemctl stop $s; "
        post+="systemctl start $s; "
    done
    for c in "${STOPPED_CONTAINERS[@]}"; do
        pre+="docker stop $c; "
        post+="docker start $c; "
    done
    [ -n "$pre" ] && HOOKS=(--pre-hook "$pre" --post-hook "$post")
}

_fetch_ips() {
    local v4 v6
    v4=$(curl -4 -s --max-time 5 https://api.ipify.org 2>/dev/null)
    [[ "$v4" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || v4=$(curl -4 -s --max-time 5 https://ifconfig.me 2>/dev/null)
    v6=$(curl -6 -s --max-time 5 https://api64.ipify.org 2>/dev/null)
    printf '%s\n%s\n' "$v4" "$v6" > "$1"
}

detect_ips() {
    local tmp
    [ "$IPS_DONE" -eq 1 ] && return 0
    tmp=$(mktemp)
    run_task -q "Detecting public IP" _fetch_ips "$tmp"
    {
        read -r SERVER_IPV4
        read -r SERVER_IPV6
    } < "$tmp"
    rm -f "$tmp"
    [[ "$SERVER_IPV4" =~ ^[0-9]+(\.[0-9]+){3}$ ]] || SERVER_IPV4=""
    [[ "$SERVER_IPV6" =~ ^[0-9a-fA-F:]+$ && "$SERVER_IPV6" == *:* ]] || SERVER_IPV6=""
    if command -v ip &>/dev/null; then
        LOCAL_IPS=$(ip -o addr show scope global 2>/dev/null | awk '{split($4, a, "/"); print a[1]}')
    else
        LOCAL_IPS=$(hostname -I 2>/dev/null | tr ' ' '\n')
    fi
    IPS_DONE=1
}

is_server_ip() {
    local ip=$1
    if [ -n "$SERVER_IPV4" ] && [ "$ip" = "$SERVER_IPV4" ]; then return 0; fi
    if [ -n "$SERVER_IPV6" ] && [ "$ip" = "$SERVER_IPV6" ]; then return 0; fi
    [ -n "$LOCAL_IPS" ] && grep -qxF "$ip" <<< "$LOCAL_IPS"
}

resolve() {
    local domain=$1 type=$2
    if command -v dig &>/dev/null; then
        dig +short +time=3 +tries=2 "$type" "$domain" 2>/dev/null | grep -v '\.$' | grep -v '^;'
    elif [ "$type" = "A" ]; then
        getent ahostsv4 "$domain" 2>/dev/null | awk '{print $1}' | sort -u
    else
        getent ahostsv6 "$domain" 2>/dev/null | awk '{print $1}' | grep -v '^::ffff:' | sort -u
    fi
}

check_dns() {
    local domain=$1 ips ip good=() bad=()
    ips=$(printf '%s\n%s\n' "$(resolve "$domain" A)" "$(resolve "$domain" AAAA)" | sed '/^$/d' | sort -u)
    if [ -z "$ips" ]; then
        warn "$domain: no A/AAAA record found"
        hint "Let's Encrypt cannot validate this domain until its DNS record exists."
        PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
        return
    fi
    for ip in $ips; do
        if is_server_ip "$ip"; then
            good+=("$ip")
        else
            bad+=("$ip")
        fi
    done
    if [ ${#bad[@]} -eq 0 ]; then
        success "$domain → ${good[*]}"
        return
    fi
    warn "$domain → ${bad[*]} does not match this server"
    [ ${#good[@]} -gt 0 ] && hint "Matching records: ${good[*]}"
    hint "This server: ${SERVER_IPV4:-unknown IPv4}${SERVER_IPV6:+ / $SERVER_IPV6}"
    if printf '%s\n' "${bad[@]}" | grep -q ':'; then
        hint "A wrong AAAA record usually breaks validation because Let's Encrypt prefers IPv6."
    fi
    hint "Behind NAT or a load balancer this can be fine. With Cloudflare, turn the proxy (orange cloud) off."
    PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
}

check_caa() {
    local domain=$1 wild=$2 d all="" records tag="issue"
    command -v dig &>/dev/null || return 0
    d="$domain"
    while [[ "$d" == *.* ]]; do
        all=$(dig +short +time=3 +tries=2 CAA "$d" 2>/dev/null | grep -iE ' issue(wild)? ')
        [ -n "$all" ] && break
        d="${d#*.}"
    done
    [ -z "$all" ] && return 0
    if [ -n "$wild" ] && grep -qi ' issuewild ' <<< "$all"; then tag="issuewild"; fi
    records=$(grep -i " $tag " <<< "$all")
    [ -z "$records" ] && return 0
    grep -qi 'letsencrypt.org' <<< "$records" && return 0
    warn "$domain: the CAA record on $d does not allow Let's Encrypt"
    hint "Add a CAA record: 0 $tag \"letsencrypt.org\""
    PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
}

check_acme_api() {
    run_task "Contacting Let's Encrypt API" curl -fsS -o /dev/null --max-time 10 "$LE_DIRECTORY" && return 0
    hint "Check outbound HTTPS access and DNS resolution on this server."
    PREFLIGHT_ERRORS=$((PREFLIGHT_ERRORS + 1))
}

check_firewall() {
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        if ufw status 2>/dev/null | grep -qE '^80(/tcp)?[[:space:]].*ALLOW'; then
            success "ufw allows port 80"
        else
            warn "ufw is active and port 80 does not look allowed"
            hint "ufw allow 80/tcp"
            PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
        fi
    fi
    if command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        if firewall-cmd --query-port=80/tcp &>/dev/null || firewall-cmd --query-service=http &>/dev/null; then
            success "firewalld allows port 80"
        else
            warn "firewalld is running and port 80 does not look allowed"
            hint "firewall-cmd --add-service=http --permanent && firewall-cmd --reload"
            PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
        fi
    fi
}

preflight_summary() {
    printf '\n'
    if [ "$PREFLIGHT_ERRORS" -gt 0 ]; then
        error "$PREFLIGHT_ERRORS error(s), $PREFLIGHT_WARNINGS warning(s)"
    elif [ "$PREFLIGHT_WARNINGS" -gt 0 ]; then
        warn "No errors, $PREFLIGHT_WARNINGS warning(s)"
    else
        success "All preflight checks passed"
    fi
}

preflight() {
    local d
    PREFLIGHT_ERRORS=0
    PREFLIGHT_WARNINGS=0

    sub "Network"
    check_acme_api
    detect_ips
    if [ -n "$SERVER_IPV4$SERVER_IPV6" ]; then
        success "Public IP: ${SERVER_IPV4:-no IPv4}${SERVER_IPV6:+ / $SERVER_IPV6}"
    else
        warn "Could not detect the public IP of this server"
        PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
    fi

    sub "DNS"
    for d in "$@"; do
        check_dns "$d"
        check_caa "$d"
    done

    sub "Ports"
    check_port 80
    case $? in
        0) PORT80_STATE="free" ;;
        1)
            PORT80_STATE="busy"
            hint "HTTP validation needs port 80 free."
            ;;
        *) PORT80_STATE="unknown" ;;
    esac
    check_port 443 info
    check_firewall
    preflight_summary
}

cf_saved() {
    [ -r "$ACME_HOME/account.conf" ] && grep -qE "^SAVED_CF_(Token|Key)=" "$ACME_HOME/account.conf"
}

cf_api() {
    local hf body
    hf=$(mktemp)
    chmod 600 "$hf"
    if [ "$DNS_METHOD" = "cf_token" ]; then
        printf 'Authorization: Bearer %s\n' "$CF_TOKEN_IN" > "$hf"
    else
        printf 'X-Auth-Email: %s\nX-Auth-Key: %s\n' "$CF_EMAIL_IN" "$CF_KEY_IN" > "$hf"
    fi
    body=$(curl -s --max-time 15 -H @"$hf" -H 'Content-Type: application/json' "$CF_API$1" 2>/dev/null)
    rm -f "$hf"
    printf '%s' "$body"
}

check_cloudflare() {
    local body d found=""
    if [ "$DNS_METHOD" = "cf_saved" ]; then
        success "Using the Cloudflare credentials saved in acme.sh"
        return 0
    fi
    if [ "$DNS_METHOD" = "cf_token" ]; then
        body=$(cf_api "/user/tokens/verify")
        if grep -qE '"status": ?"active"' <<< "$body"; then
            success "Cloudflare API token is valid and active"
        else
            error "Cloudflare rejected the API token"
            hint "Create a token with the 'Edit zone DNS' template: Zone → DNS → Edit and Zone → Zone → Read."
            hint "$CF_TOKEN_PAGE"
            PREFLIGHT_ERRORS=$((PREFLIGHT_ERRORS + 1))
            return 1
        fi
    else
        body=$(cf_api "/user")
        if grep -qE '"success": ?true' <<< "$body"; then
            success "Cloudflare Global API Key is valid"
        else
            error "Cloudflare rejected the Global API Key or the account email"
            hint "$CF_TOKEN_PAGE → Global API Key → View"
            PREFLIGHT_ERRORS=$((PREFLIGHT_ERRORS + 1))
            return 1
        fi
    fi
    d=$1
    while [[ "$d" == *.* ]]; do
        body=$(cf_api "/zones?name=$d")
        if grep -qE '"count": ?[1-9]' <<< "$body"; then
            found=$d
            break
        fi
        d=${d#*.}
    done
    if [ -n "$found" ]; then
        success "Zone $found found in your Cloudflare account"
    else
        warn "No Cloudflare zone was found for $1"
        hint "The domain must be added to this Cloudflare account, and the token needs Zone → Zone → Read."
        PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
    fi
}

find_zone_ns() {
    local d=$1 ns
    ZONE_NAME=""
    ZONE_NS=""
    command -v dig &>/dev/null || return 1
    while [[ "$d" == *.* ]]; do
        ns=$(dig +short +time=3 +tries=2 NS "$d" 2>/dev/null | grep '\.$')
        if [ -n "$ns" ]; then
            ZONE_NAME=$d
            ZONE_NS=$ns
            return 0
        fi
        d=${d#*.}
    done
    return 1
}

check_ns() {
    if ! find_zone_ns "$1"; then
        warn "Could not find the nameservers of $1"
        PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
        return
    fi
    success "Nameservers of $ZONE_NAME: $(tr '\n' ' ' <<< "$ZONE_NS")"
    if [[ "$DNS_METHOD" == cf_* ]] && ! grep -qi 'ns\.cloudflare\.com' <<< "$ZONE_NS"; then
        warn "$ZONE_NAME does not use Cloudflare nameservers"
        hint "Cloudflare DNS validation only works when the domain's DNS is hosted on Cloudflare."
        PREFLIGHT_WARNINGS=$((PREFLIGHT_WARNINGS + 1))
    fi
}

preflight_dns() {
    PREFLIGHT_ERRORS=0
    PREFLIGHT_WARNINGS=0

    sub "Network"
    check_acme_api

    sub "DNS"
    check_ns "$1"
    check_caa "$1" wildcard
    success "Port 80 is not needed for DNS validation"

    if [[ "$DNS_METHOD" == cf_* ]]; then
        sub "Cloudflare"
        check_cloudflare "$1"
    fi
    preflight_summary
}

explain_failure() {
    local f=$1
    [ -s "$f" ] || return 0
    if grep -qiE 'forbidden by policy|rejectedIdentifier' "$f"; then
        hint "Let's Encrypt refuses to issue for this domain name by policy."
    elif grep -qiE 'rateLimited|too many' "$f"; then
        hint "Rate limit reached. Wait before trying again."
    elif grep -qiE 'invalid api token|Invalid request headers|Authentication error|error: 10000' "$f"; then
        hint "Cloudflare refused the credentials. Check the token permissions or the Global API Key."
    elif grep -qiE 'invalid domain|Can not find the domain' "$f"; then
        hint "Cloudflare could not find the zone. Is the domain added to this Cloudflare account?"
    elif grep -qiE 'Incorrect TXT record|No TXT record|NXDOMAIN looking up TXT' "$f"; then
        hint "The TXT records were missing or wrong when Let's Encrypt checked. Wait a little longer and renew."
    elif grep -qiE 'NXDOMAIN|no valid A records|DNS problem' "$f"; then
        hint "DNS problem: check the DNS records of the domain."
    elif grep -qiE 'CAA' "$f"; then
        hint "A CAA record is blocking Let's Encrypt."
    elif grep -qiE 'Timeout|Connection refused|connection reset' "$f"; then
        hint "Let's Encrypt could not reach port 80. Check the provider firewall or security group."
    elif grep -qiE 'unauthorized|Invalid response|404' "$f"; then
        hint "Another server answered on port 80. The domain may point to a CDN or a different IP."
    elif grep -qiE 'already in use|Address in use' "$f"; then
        hint "Port 80 was busy during validation."
    fi
}

show_failure_tail() {
    local l
    [ -s "$LAST_OUTPUT" ] || return 0
    if [ "$VERBOSE" -eq 0 ] && [ "$IS_TTY" -eq 1 ]; then
        tail -n "${1:-10}" "$LAST_OUTPUT" | sed 's/\x1b\[[0-9;]*m//g' | while IFS= read -r l; do
            printf '    %s\n' "${gray}│ ${l}${reset}"
        done
    fi
    hint "Full log: $LOG_FILE"
}

staging_test() {
    local args=() d tmp rc
    for d in "$@"; do args+=(-d "$d"); done
    tmp=$(mktemp -d)
    if [ -x "$ACME" ] && command -v socat &>/dev/null; then
        run_task "Test certificate from Let's Encrypt staging" "$ACME" --issue --standalone "${args[@]}" \
            --server letsencrypt_test --config-home "$tmp" ${email:+--accountemail "$email"}
        rc=$?
    elif command -v certbot &>/dev/null; then
        run_task "Test certificate from Let's Encrypt staging" certbot certonly --standalone --dry-run "${args[@]}" \
            --non-interactive --agree-tos --register-unsafely-without-email \
            --config-dir "$tmp/cfg" --work-dir "$tmp/work" --logs-dir "$tmp/logs"
        rc=$?
    else
        warn "acme.sh and certbot are both missing, the staging test was skipped"
        rm -rf "$tmp"
        return 2
    fi
    rm -rf "$tmp"
    if [ "$rc" -eq 0 ]; then
        success "Staging test passed, a real certificate can be obtained"
        return 0
    fi
    explain_failure "$LAST_OUTPUT"
    show_failure_tail 12
    return 1
}

_acme_issue() {
    local rc
    "$ACME" "$@"
    rc=$?
    case "$rc" in
        2)
            echo "VESSL_SKIPPED"
            return 0
            ;;
        3)
            echo "VESSL_MANUAL"
            return 0
            ;;
    esac
    return "$rc"
}

_acme_cf_issue() {
    case "$DNS_METHOD" in
        cf_token) export CF_Token="$CF_TOKEN_IN" ;;
        cf_key) export CF_Key="$CF_KEY_IN" CF_Email="$CF_EMAIL_IN" ;;
    esac
    _acme_issue "$@"
}

acme_install_files() {
    mkdir -p "$destination" || {
        error "Could not create $destination"
        return 1
    }
    run_task "Installing certificate files" "$ACME" --install-cert -d "${DOMAINS[0]}" --ecc \
        --key-file "${destination}privkey.pem" \
        --fullchain-file "${destination}fullchain.pem" || return 1
    ENGINE="acme.sh"
}

issue_with_acme() {
    local args=() extra=() d
    [ -x "$ACME" ] || {
        warn "acme.sh is not installed"
        return 1
    }
    command -v socat &>/dev/null || {
        warn "socat is missing, acme.sh standalone mode needs it"
        return 1
    }
    for d in "${DOMAINS[@]}"; do args+=(-d "$d"); done
    [ "$FORCE" -eq 1 ] && extra+=(--force)

    run_task "Requesting certificate via acme.sh" _acme_issue --issue --standalone "${args[@]}" \
        --server letsencrypt --keylength ec-256 --accountemail "$email" "${HOOKS[@]}" "${extra[@]}" || return 1
    if grep -q VESSL_SKIPPED "$LAST_OUTPUT"; then
        log "The current certificate is still valid and was kept. Use Renew or --force to replace it."
    fi
    acme_install_files
}

issue_with_certbot() {
    local args=() extra=() d main="${DOMAINS[0]}" live
    command -v certbot &>/dev/null || {
        warn "certbot is not installed"
        return 1
    }
    for d in "${DOMAINS[@]}"; do args+=(-d "$d"); done
    [ "$FORCE" -eq 1 ] && extra+=(--force-renewal)
    live="/etc/letsencrypt/live/$main"
    mkdir -p "$destination" || {
        error "Could not create $destination"
        return 1
    }

    run_task "Requesting certificate via certbot" certbot certonly --standalone "${args[@]}" \
        --cert-name "$main" --non-interactive --agree-tos --email "$email" \
        --deploy-hook "cp -L '$live/privkey.pem' '${destination}privkey.pem' && cp -L '$live/fullchain.pem' '${destination}fullchain.pem'" \
        "${HOOKS[@]}" "${extra[@]}" || return 1

    cp -L "$live/privkey.pem" "${destination}privkey.pem" && cp -L "$live/fullchain.pem" "${destination}fullchain.pem" || return 1
    ENGINE="certbot"
}

parse_txt_records() {
    local kind val name=""
    TXT_NAMES=()
    TXT_VALUES=()
    while read -r kind val; do
        case "$kind" in
            N) name=$val ;;
            V)
                if [ -n "$name" ] && [ -n "$val" ]; then
                    TXT_NAMES+=("$name")
                    TXT_VALUES+=("$val")
                fi
                ;;
        esac
    done < <(sed 's/\x1b\[[0-9;]*m//g' "$LAST_OUTPUT" | sed -n "s/.*Domain: '\([^']*\)'.*/N \1/p; s/.*TXT value: '\([^']*\)'.*/V \1/p")
    [ ${#TXT_NAMES[@]} -gt 0 ]
}

show_txt_records() {
    local i n=${#TXT_NAMES[@]} rel
    printf '\n'
    box_top "Add these DNS records"
    box_row "Add ${bold}$n TXT record(s)${reset} at your DNS provider, then come back here."
    box_row "${gray}They share the same name. Keep all of them, do not replace one.${reset}"
    box_bottom
    for i in "${!TXT_NAMES[@]}"; do
        rel=""
        if [ -n "$ZONE_NAME" ] && [[ "${TXT_NAMES[$i]}" == *".$ZONE_NAME" ]]; then
            rel=${TXT_NAMES[$i]%".$ZONE_NAME"}
        fi
        printf '\n  %s\n' "${purple}${bold}Record $((i + 1)) of $n${reset}"
        printf '    %s %s\n' "${gray}Type ${reset}" "TXT"
        printf '    %s %s\n' "${gray}Name ${reset}" "${bold}${TXT_NAMES[$i]}${reset}"
        [ -n "$rel" ] && printf '    %s %s\n' "${gray}     ${reset}" "${gray}in most DNS panels just: ${reset}${bold}$rel${reset}"
        printf '    %s %s\n' "${gray}Value${reset}" "${bold}${TXT_VALUES[$i]}${reset}"
        printf '    %s %s\n' "${gray}TTL  ${reset}" "the lowest allowed, or Auto"
    done
    printf '\n'
    hint "On Cloudflare, TXT records are never proxied, so there is nothing else to change."
}

_wait_txt() {
    local limit=$1 ns=$2 deadline i ok
    deadline=$((SECONDS + limit))
    while [ "$SECONDS" -lt "$deadline" ]; do
        ok=1
        for i in "${!TXT_NAMES[@]}"; do
            if ! dig +short +time=3 +tries=1 TXT "${TXT_NAMES[$i]}" ${ns:+@"$ns"} 2>/dev/null | tr -d '"' | grep -qxF "${TXT_VALUES[$i]}"; then
                ok=0
                echo "waiting for ${TXT_NAMES[$i]} = ${TXT_VALUES[$i]}"
                break
            fi
        done
        [ "$ok" -eq 1 ] && return 0
        sleep 10
    done
    return 1
}

cert_info() {
    local f=$1 s e c_start c_end
    C_DAYS=0
    C_TOTAL=90
    C_END_DATE=""
    [ -f "$f" ] || return 1
    command -v openssl &>/dev/null || return 1
    s=$(openssl x509 -startdate -noout -in "$f" 2>/dev/null | cut -d= -f2)
    e=$(openssl x509 -enddate -noout -in "$f" 2>/dev/null | cut -d= -f2)
    [ -n "$e" ] || return 1
    c_end=$(date -d "$e" +%s 2>/dev/null) || return 1
    c_start=$(date -d "$s" +%s 2>/dev/null) || c_start=$((c_end - 7776000))
    C_DAYS=$(((c_end - $(date +%s)) / 86400))
    C_TOTAL=$(((c_end - c_start) / 86400))
    ((C_TOTAL < 1)) && C_TOTAL=90
    C_END_DATE=$(date -d "$e" +%F)
}

cert_domains() {
    openssl x509 -noout -text -in "$1" 2>/dev/null | grep -A1 'Subject Alternative Name' | tail -n1 | grep -oE 'DNS:[^, ]+' | cut -c5-
}

cert_engines() {
    local main=$1
    HAS_ACME=0
    HAS_CERTBOT=0
    [[ "$main" =~ ^[a-z0-9.-]+$ && "$main" == *.* ]] || return 0
    if [ -x "$ACME" ] && { [ -d "$ACME_HOME/${main}_ecc" ] || [ -d "$ACME_HOME/$main" ]; }; then HAS_ACME=1; fi
    if command -v certbot &>/dev/null && [ -f "/etc/letsencrypt/renewal/$main.conf" ]; then HAS_CERTBOT=1; fi
}

life_bar() {
    local d=$1 t=$2 w=${3:-16} f c
    f=$((d * w / t))
    ((f < 0)) && f=0
    ((f > w)) && f=$w
    if ((d > 30)); then c=$green; elif ((d > 7)); then c=$orange; else c=$red; fi
    printf '%s%s%s%s' "$c" "$(rep █ "$f")" "${gray}$(rep ░ $((w - f)))" "$reset"
}

days_text() {
    local d=$1 c
    if ((d < 0)); then
        printf '%s' "${red}expired${reset}"
        return
    fi
    if ((d > 30)); then c=$green; elif ((d > 7)); then c=$orange; else c=$red; fi
    printf '%s' "${c}${d} days left${reset}"
}

renew_text() {
    case "$1" in
        http) printf '%s' "auto-renew · HTTP" ;;
        dns_cf) printf '%s' "auto-renew · Cloudflare DNS" ;;
        dns_manual) printf '%s' "${orange}manual renew · DNS TXT${reset}" ;;
    esac
}

collect_certs() {
    local d rp p b f seen="|"
    CERT_DIRS=()
    while IFS= read -r d; do
        [ -n "$d" ] || continue
        [ -f "${d%/}/fullchain.pem" ] || continue
        rp=$(readlink -f "${d%/}")
        [[ "$seen" == *"|$rp|"* ]] && continue
        seen+="$rp|"
        CERT_DIRS+=("$rp/")
    done < <(
        [ -r "$REGISTRY_FILE" ] && cut -d'|' -f3 "$REGISTRY_FILE"
        for p in "${PANELS[@]}"; do
            b=$(panel_base "$p")
            for f in "$b"/*/fullchain.pem; do
                [ -f "$f" ] && echo "${f%fullchain.pem}"
            done
        done
    )
}

print_cert_list() {
    local i d name meta tags
    collect_certs
    if [ ${#CERT_DIRS[@]} -eq 0 ]; then
        warn "No certificates found"
        hint "Certificates issued with VESSL, and any fullchain.pem inside panel cert folders, show up here."
        return 1
    fi
    for i in "${!CERT_DIRS[@]}"; do
        d=${CERT_DIRS[$i]}
        name=$(basename "$d")
        if cert_info "${d}fullchain.pem"; then
            printf '  %s  %s %s  %s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "${bold}$(fit "$name" 26)${reset}" 27)" \
                "$(life_bar "$C_DAYS" "$C_TOTAL")" "$(days_text "$C_DAYS") ${gray}· $C_END_DATE${reset}"
        else
            printf '  %s  %s %s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "${bold}$(fit "$name" 26)${reset}" 27)" "${red}unreadable certificate${reset}"
        fi
        tags=""
        cert_domains "${d}fullchain.pem" | grep -q '^\*\.' && tags+=" · wildcard"
        meta=$(renew_text "$(reg_field "$d" 6)")
        [ -n "$meta" ] && tags+=" · $meta"
        printf '         %s%s\n' "${gray}$d${reset}" "${gray}${tags}${reset}"
    done
}

pick_cert() {
    local c n
    printf '\n'
    print_cert_list || return 1
    n=${#CERT_DIRS[@]}
    printf '\n'
    while true; do
        c=$(ask "Select a certificate, 0 to go back") || return 1
        case "$c" in
            0|q) return 1 ;;
            ''|*[!0-9]*) warn "Enter a number from the list" ;;
            *)
                c=$((10#$c))
                if ((c >= 1 && c <= n)); then
                    SEL_DIR=${CERT_DIRS[$((c - 1))]}
                    return 0
                fi
                warn "Enter a number from the list"
                ;;
        esac
    done
}

show_plan() {
    printf '\n'
    box_top "Summary"
    box_kv "Email" "$email"
    box_kv "Domains" "${DOMAINS[*]}"
    if [ "$WILDCARD" -eq 1 ]; then
        box_kv "Validation" "$(dns_method_title "$DNS_METHOD")"
    else
        box_kv "Validation" "HTTP on port 80"
    fi
    box_kv "Save to" "$destination"
    box_kv "Files" "privkey.pem · fullchain.pem"
    [ "$RUN_TEST" -eq 1 ] && box_kv "Test" "staging test before the real request"
    [ "$FORCE" -eq 1 ] && box_kv "Mode" "force renew"
    [ "$SKIP_CHECK" -eq 1 ] && box_kv "Checks" "skipped"
    if [ "$WILDCARD" -eq 1 ] && [ "$DNS_METHOD" = "manual" ]; then
        box_row "${orange}Manual DNS cannot renew by itself. Renew with VESSL every ~60 days.${reset}"
    fi
    box_bottom
    if is_custom_path "$DEST_TARGET"; then
        hint "Custom path: a trailing slash makes no difference, the files go in a folder named ${DOMAINS[0]}."
    fi
}

show_result() {
    local stopped=$1 method=$2
    cert_info "${destination}fullchain.pem"
    printf '\n'
    box_top "Certificate ready"
    box_kv "Domains" "${DOMAINS[*]}"
    box_kv "Engine" "$ENGINE"
    box_kv "Expires" "$C_END_DATE · $C_DAYS days"
    box_row "$(col "${gray}Lifetime${reset}" 13)$(life_bar "$C_DAYS" "$C_TOTAL" 30)"
    case "$method" in
        dns_cf) box_kv "Renewal" "automatic, acme.sh cron + Cloudflare API" ;;
        dns_manual) box_row "$(col "${gray}Renewal${reset}" 13)${orange}manual, renew with VESSL before $(date -d "+60 days" +%F)${reset}" ;;
        *)
            if [ "$ENGINE" = "acme.sh" ]; then
                box_kv "Renewal" "automatic, acme.sh cron job"
            else
                box_kv "Renewal" "automatic, certbot timer"
            fi
            ;;
    esac
    box_bottom
    printf '\n  %s %s\n' "${gray}Private key${reset}" "${bold}${destination}privkey.pem${reset}"
    printf '  %s %s\n' "${gray}Full chain ${reset}" "${bold}${destination}fullchain.pem${reset}"
    if [ -n "${stopped// /}" ]; then
        hint "Auto-renew will stop and start ${stopped% } to free port 80."
    fi
    if [ "$method" = "dns_manual" ]; then
        hint "The acme.sh cron job cannot answer DNS challenges by itself and will log errors for this certificate."
        hint "Open VESSL → Renew certificate before it expires and add the new TXT records."
    fi
}

reset_run_state() {
    PORT80_STATE=""
    PORT_OWNERS=()
    HOOKS=()
    STEP_CUR=0
    ENGINE=""
    PREFLIGHT_ERRORS=0
    PREFLIGHT_WARNINGS=0
    TXT_NAMES=()
    TXT_VALUES=()
}

do_issue() {
    local stopped=""
    reset_run_state
    STEP_TOTAL=4
    [ "$SKIP_CHECK" -eq 0 ] && STEP_TOTAL=$((STEP_TOTAL + 1))
    [ "$RUN_TEST" -eq 1 ] && STEP_TOTAL=$((STEP_TOTAL + 1))

    step "Preparing dependencies"
    install_dependencies
    if cert_info "${destination}fullchain.pem"; then
        log "Current certificate here expires on $C_END_DATE ($C_DAYS days left)"
    fi

    if [ "$SKIP_CHECK" -eq 0 ]; then
        step "Preflight checks"
        preflight "${DOMAINS[@]}"
        if [ "$PREFLIGHT_ERRORS" -gt 0 ]; then
            error "Fix the errors above and try again."
            return 1
        fi
        if [ "$PREFLIGHT_WARNINGS" -gt 0 ] && ! ask_continue "There are warnings. Continue anyway?"; then
            log "Cancelled"
            return 1
        fi
    fi

    step "Freeing port 80"
    free_port 80 || return 1
    build_hooks

    if [ "$RUN_TEST" -eq 1 ]; then
        step "Staging test"
        if ! staging_test "${DOMAINS[@]}"; then
            if ! confirm "The staging test did not pass. Try the real request anyway?"; then
                restore_services
                return 1
            fi
        fi
    fi

    step "Requesting certificate"
    if ! issue_with_acme; then
        explain_failure "$LAST_OUTPUT"
        warn "acme.sh did not succeed, trying certbot"
        if ! issue_with_certbot; then
            explain_failure "$LAST_OUTPUT"
            show_failure_tail 12
            error "Could not obtain a certificate with acme.sh or certbot"
            restore_services
            return 1
        fi
    fi

    step "Finishing up"
    [ ${#HOOKS[@]} -gt 0 ] && stopped="${STOPPED_SERVICES[*]} ${STOPPED_CONTAINERS[*]}"
    restore_services
    reg_save "${DOMAINS[0]}" "$(IFS=,; echo "${DOMAINS[*]}")" "$destination" "$email" "$ENGINE" "http"
    success "Saved to the VESSL certificate list"
    steps_done "Certificate issued"
    show_result "$stopped" "http"
    printf '\n'
    support_box
    return 0
}

do_issue_dns() {
    local args=() extra=() d base=${DOMAINS[0]} method need_validate=1
    method=$(method_family "$DNS_METHOD")
    reset_run_state
    STEP_TOTAL=3
    [ "$SKIP_CHECK" -eq 0 ] && STEP_TOTAL=$((STEP_TOTAL + 1))
    [ "$DNS_METHOD" = "manual" ] && STEP_TOTAL=$((STEP_TOTAL + 2))
    for d in "${DOMAINS[@]}"; do args+=(-d "$d"); done
    [ "$FORCE" -eq 1 ] && extra+=(--force)

    step "Preparing dependencies"
    install_dependencies
    if [ ! -x "$ACME" ]; then
        error "Wildcard certificates need acme.sh, and it is not available."
        show_failure_tail 8
        return 1
    fi
    if cert_info "${destination}fullchain.pem"; then
        log "Current certificate here expires on $C_END_DATE ($C_DAYS days left)"
    fi

    if [ "$SKIP_CHECK" -eq 0 ]; then
        step "Preflight checks"
        preflight_dns "$base"
        if [ "$PREFLIGHT_ERRORS" -gt 0 ]; then
            error "Fix the errors above and try again."
            return 1
        fi
        if [ "$PREFLIGHT_WARNINGS" -gt 0 ] && ! ask_continue "There are warnings. Continue anyway?"; then
            log "Cancelled"
            return 1
        fi
    else
        find_zone_ns "$base"
    fi

    if [ "$DNS_METHOD" = "manual" ]; then
        step "Creating the DNS challenge"
        if ! run_task "Asking Let's Encrypt for a DNS challenge" _acme_issue --issue --dns "${args[@]}" \
            --server letsencrypt --keylength ec-256 --accountemail "$email" \
            --yes-I-know-dns-manual-mode-enough-go-ahead-please "${extra[@]}"; then
            explain_failure "$LAST_OUTPUT"
            show_failure_tail 12
            return 1
        fi
        if grep -q VESSL_SKIPPED "$LAST_OUTPUT"; then
            log "The current certificate is still valid and was kept. Use Renew or --force to replace it."
            need_validate=0
        elif grep -q VESSL_MANUAL "$LAST_OUTPUT"; then
            if ! parse_txt_records; then
                error "Could not read the TXT records from the acme.sh output"
                show_failure_tail 20
                return 1
            fi
            show_txt_records
            if [ ! -t 0 ]; then
                error "Manual DNS mode needs an interactive terminal"
                return 1
            fi
            read -r -p "  ${cyan}❯${reset} Press Enter after all records are added " _ || return 1
            step "Waiting for DNS"
            if command -v dig &>/dev/null; then
                if ! run_task "Waiting for the TXT records to show up in DNS" _wait_txt "$TXT_WAIT_SECONDS" "$(head -n1 <<< "$ZONE_NS" | sed 's/\.$//')"; then
                    warn "The records are not visible yet on the ${ZONE_NAME:+$ZONE_NAME }nameservers"
                    confirm "Try the validation anyway?" || return 1
                fi
            else
                warn "dig is not installed, cannot check the records. Waiting 60 seconds."
                run_task "Giving DNS some time" sleep 60
            fi
        else
            log "Let's Encrypt reused a recent validation, no new TXT records are needed"
            need_validate=0
        fi
        step "Requesting certificate"
        if [ "$need_validate" -eq 1 ]; then
            if ! run_task "Validating the TXT records and issuing" "$ACME" --renew -d "$base" --ecc --force \
                --yes-I-know-dns-manual-mode-enough-go-ahead-please; then
                explain_failure "$LAST_OUTPUT"
                show_failure_tail 12
                error "Validation failed. Run it again from VESSL; new TXT values may be needed."
                return 1
            fi
        fi
    else
        step "Requesting certificate"
        if ! run_task "Requesting wildcard certificate via Cloudflare DNS" _acme_cf_issue --issue --dns dns_cf "${args[@]}" \
            --server letsencrypt --keylength ec-256 --accountemail "$email" "${extra[@]}"; then
            explain_failure "$LAST_OUTPUT"
            show_failure_tail 12
            return 1
        fi
        if grep -q VESSL_SKIPPED "$LAST_OUTPUT"; then
            log "The current certificate is still valid and was kept. Use Renew or --force to replace it."
        fi
    fi
    acme_install_files || return 1

    step "Finishing up"
    reg_save "$base" "$(IFS=,; echo "${DOMAINS[*]}")" "$destination" "$email" "$ENGINE" "$method"
    success "Saved to the VESSL certificate list"
    steps_done "Wildcard certificate issued"
    show_result "" "$method"
    printf '\n'
    support_box
    return 0
}

run_issue_flow() {
    if [ "$WILDCARD" -eq 1 ]; then
        do_issue_dns
    else
        do_issue
    fi
}

run_check_flow() {
    local test_rc=2 port_ok=0
    reset_run_state
    STEP_TOTAL=3

    step "Preflight checks"
    preflight "${DOMAINS[@]}"

    step "Port 80"
    if [ "$PREFLIGHT_ERRORS" -gt 0 ]; then
        warn "Skipped because of preflight errors"
    else
        if [ ! -x "$ACME" ] && ! command -v certbot &>/dev/null; then
            if confirm "acme.sh and certbot are missing. Install them to run the staging test?"; then
                install_dependencies
            fi
        fi
        free_port 80 && port_ok=1
    fi

    step "Staging test"
    if [ "$port_ok" -eq 1 ]; then
        staging_test "${DOMAINS[@]}"
        test_rc=$?
        restore_services
    else
        warn "Skipped"
    fi

    steps_done "Check complete"
    printf '\n'
    box_top "Result"
    if [ "$test_rc" -eq 0 ]; then
        box_row "${green}✓${reset} A certificate can be obtained for ${DOMAINS[*]}"
        box_bottom
        return 0
    elif [ "$test_rc" -eq 1 ] || [ "$PREFLIGHT_ERRORS" -gt 0 ]; then
        box_row "${red}✗${reset} A certificate can NOT be obtained right now"
        box_bottom
        return 1
    fi
    box_row "${orange}⚠${reset} The full test could not run, review the warnings above"
    box_bottom
    return 2
}

ask_email() {
    local v
    while true; do
        v=$(ask "Email" "$DEFAULT_EMAIL") || return 1
        [ "$v" = "0" ] && return 1
        if [ -z "$v" ]; then
            warn "Let's Encrypt needs an email address"
            continue
        fi
        if validate_email "$v"; then
            email=$v
            return 0
        fi
    done
}

ask_domains() {
    local v arr=()
    hint "Separate multiple domains with a space or a comma. The first one names the folder."
    while true; do
        v=$(ask "Domains") || return 1
        [ "$v" = "0" ] && return 1
        [ -z "$v" ] && continue
        read -ra arr <<< "${v//,/ }"
        prepare_domains "${arr[@]}" && return 0
    done
}

ask_base_domain() {
    local v
    hint "Enter the main domain, for example example.com. Typing *.example.com works too."
    hint "The certificate will cover example.com and *.example.com."
    while true; do
        v=$(ask "Domain") || return 1
        [ "$v" = "0" ] && return 1
        [ -z "$v" ] && continue
        prepare_wildcard "$v" && return 0
    done
}

pick_dns_method() {
    local opts=() i c
    cf_saved && opts+=(cf_saved)
    opts+=(cf_token cf_key manual)
    sub "How should VESSL prove you own the domain?"
    printf '\n'
    for i in "${!opts[@]}"; do
        case "${opts[$i]}" in
            cf_saved) printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "Cloudflare, saved" 27)" "${gray}use the credentials acme.sh already has${reset}" ;;
            cf_token) printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "Cloudflare API token" 27)" "${gray}recommended, renews automatically${reset}" ;;
            cf_key) printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "Cloudflare Global API Key" 27)" "${gray}older method, renews automatically${reset}" ;;
            manual) printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "Manual DNS records" 27)" "${gray}any DNS provider, renew by hand${reset}" ;;
        esac
    done
    printf '  %s  %s\n\n' "$(col "${cyan}${bold}[0]${reset}" 5)" "Back"
    while true; do
        c=$(ask "Select" "1") || return 1
        case "$c" in
            0|q) return 1 ;;
            ''|*[!0-9]*) warn "Enter a number from the list" ;;
            *)
                c=$((10#$c))
                if ((c >= 1 && c <= ${#opts[@]})); then
                    DNS_METHOD=${opts[$((c - 1))]}
                    return 0
                fi
                warn "Enter a number from the list"
                ;;
        esac
    done
}

ask_cf_credentials() {
    local v
    case "$DNS_METHOD" in
        cf_token)
            printf '\n'
            hint "Create a token at $CF_TOKEN_PAGE"
            hint "Use the 'Edit zone DNS' template, or give it Zone → DNS → Edit and Zone → Zone → Read."
            hint "acme.sh saves it so the certificate renews automatically."
            while true; do
                v=$(ask_secret "Cloudflare API token") || return 1
                [ "$v" = "0" ] && return 1
                if [ -n "$v" ]; then
                    CF_TOKEN_IN=$v
                    return 0
                fi
            done
            ;;
        cf_key)
            printf '\n'
            hint "Find it at $CF_TOKEN_PAGE → Global API Key → View."
            hint "It has full access to your account; an API token is safer."
            while true; do
                v=$(ask "Cloudflare account email" "$email") || return 1
                [ "$v" = "0" ] && return 1
                validate_email "$v" && break
            done
            CF_EMAIL_IN=$v
            while true; do
                v=$(ask_secret "Global API Key") || return 1
                [ "$v" = "0" ] && return 1
                if [ -n "$v" ]; then
                    CF_KEY_IN=$v
                    return 0
                fi
            done
            ;;
        manual)
            printf '\n'
            warn "Manual DNS certificates cannot renew automatically."
            hint "Every ~60 days, open VESSL → Renew certificate and add the new TXT records it shows."
            ;;
    esac
    return 0
}

ask_custom_path() {
    local p d def=""
    is_custom_path "$DEFAULT_DEST" && def=$DEFAULT_DEST
    printf '\n'
    hint "Enter an absolute path that starts with '/'."
    hint "A trailing slash is optional: /root/certs and /root/certs/ are the same."
    hint "VESSL creates a folder named after the first domain inside it."
    while true; do
        p=$(ask "Path" "$def") || return 1
        [ "$p" = "0" ] && return 1
        if ! is_custom_path "$p"; then
            warn "The path must start with '/', for example /root/certs"
            continue
        fi
        DEST_TARGET=$(norm_path "$p")
        d=$DEST_TARGET
        [ "$d" = "/" ] && d=""
        log "Files will be saved in ${bold}${d}/${DOMAINS[0]:-<domain>}/${reset}"
        return 0
    done
}

pick_destination() {
    local i n=${#PANELS[@]} c def="" p
    sub "Where should the certificate be saved?"
    printf '\n'
    for i in "${!PANELS[@]}"; do
        p=${PANELS[$i]}
        [ "$p" = "$DEFAULT_DEST" ] && def=$((i + 1))
        printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((i + 1))]${reset}" 5)" "$(col "$(panel_title "$p")" 14)" "${gray}$(panel_base "$p")/${reset}"
    done
    printf '  %s  %s%s\n' "$(col "${cyan}${bold}[$((n + 1))]${reset}" 5)" "$(col "Custom path" 14)" "${gray}any folder you choose${reset}"
    printf '  %s  %s\n\n' "$(col "${cyan}${bold}[0]${reset}" 5)" "Back"
    [ -z "$def" ] && is_custom_path "$DEFAULT_DEST" && def=$((n + 1))
    while true; do
        c=$(ask "Select" "$def") || return 1
        case "$c" in
            0|q) return 1 ;;
            ''|*[!0-9]*) warn "Enter a number from the list" ;;
            *)
                c=$((10#$c))
                if ((c >= 1 && c <= n)); then
                    DEST_TARGET=${PANELS[$((c - 1))]}
                    return 0
                elif ((c == n + 1)); then
                    ask_custom_path
                    return $?
                fi
                warn "Enter a number from the list"
                ;;
        esac
    done
}

wizard_issue() {
    section "Issue a certificate"
    hint "One or more domains, validated over HTTP on port 80."
    hint "Type 0 at any prompt to go back."
    printf '\n'
    WILDCARD=0
    ask_email || return 1
    ask_domains || return 1
    pick_destination || return 1
    resolve_destination "$DEST_TARGET" || return 1
    FORCE=0
    SKIP_CHECK=0
    RUN_TEST=0
    printf '\n'
    confirm "Run a free staging test before the real request?" && RUN_TEST=1
    show_plan
    printf '\n'
    if ! ask_continue "Start?"; then
        log "Cancelled"
        return 1
    fi
    if do_issue; then
        DEFAULT_EMAIL=$email
        DEFAULT_DEST=$DEST_TARGET
        save_config
        return 0
    fi
    return 1
}

wizard_wildcard() {
    local rc=1
    section "Issue a wildcard certificate"
    hint "Covers example.com and every subdomain (*.example.com)."
    hint "Validation is done through DNS, so port 80 is not needed."
    hint "Type 0 at any prompt to go back."
    printf '\n'
    WILDCARD=1
    ask_email || return 1
    ask_base_domain || return 1
    pick_dns_method || return 1
    ask_cf_credentials || return 1
    pick_destination || return 1
    resolve_destination "$DEST_TARGET" || return 1
    FORCE=0
    SKIP_CHECK=0
    RUN_TEST=0
    show_plan
    printf '\n'
    if ask_continue "Start?"; then
        if do_issue_dns; then
            DEFAULT_EMAIL=$email
            DEFAULT_DEST=$DEST_TARGET
            save_config
            rc=0
        fi
    else
        log "Cancelled"
    fi
    clear_secrets
    return $rc
}

wizard_check() {
    section "Check a domain"
    hint "Runs every preflight check and a free test on Let's Encrypt staging."
    hint "Nothing real is issued and your current certificates are not touched."
    hint "This checks HTTP validation. Wildcard checks run automatically when you issue one."
    hint "Type 0 to go back."
    printf '\n'
    WILDCARD=0
    ask_domains || return 1
    email=$DEFAULT_EMAIL
    run_check_flow
}

wizard_renew() {
    local line main d list=() method rc=1
    section "Renew a certificate"
    pick_cert || return 1
    destination=$SEL_DIR
    main=$(basename "$destination")
    line=$(reg_get "$destination")
    if [ -n "$line" ]; then
        IFS=',' read -ra list <<< "$(cut -d'|' -f2 <<< "$line")"
        email=$(cut -d'|' -f4 <<< "$line")
        method=$(cut -d'|' -f6 <<< "$line")
    else
        mapfile -t list < <(cert_domains "${destination}fullchain.pem")
        email=""
        method=""
    fi
    WILDCARD=0
    has_wildcard "${list[@]}" && WILDCARD=1
    DOMAINS=("$main")
    for d in "${list[@]}"; do
        [ "$d" != "$main" ] && [ -n "$d" ] && DOMAINS+=("$d")
    done
    prepare_domains "${DOMAINS[@]}" || return 1
    [ -n "$email" ] || email=$DEFAULT_EMAIL
    if [ -z "$email" ]; then
        printf '\n'
        ask_email || return 1
    fi
    if [ "$WILDCARD" -eq 1 ]; then
        case "$method" in
            dns_manual) DNS_METHOD="manual" ;;
            dns_cf)
                if cf_saved; then
                    DNS_METHOD="cf_saved"
                else
                    { pick_dns_method && ask_cf_credentials; } || return 1
                fi
                ;;
            *) { pick_dns_method && ask_cf_credentials; } || return 1 ;;
        esac
    fi
    DEST_TARGET=""
    FORCE=1
    RUN_TEST=0
    SKIP_CHECK=0
    show_plan
    printf '\n'
    if ask_continue "Renew now?"; then
        run_issue_flow && rc=0
    else
        log "Cancelled"
    fi
    clear_secrets
    return $rc
}

_remove_acme_entry() {
    "$ACME" --remove -d "$1" --ecc
    "$ACME" --remove -d "$1"
    rm -rf "${ACME_HOME:?}/${1}_ecc" "${ACME_HOME:?}/$1"
    return 0
}

revoke_cert() {
    local dir=$1 main
    main=$(basename "$dir")
    cert_engines "$main"
    if [ "$HAS_ACME" -eq 1 ]; then
        run_task "Revoking $main at Let's Encrypt" "$ACME" --revoke -d "$main" --ecc
    elif [ "$HAS_CERTBOT" -eq 1 ]; then
        run_task "Revoking $main at Let's Encrypt" certbot revoke --cert-name "$main" --non-interactive --no-delete-after-revoke
    elif command -v certbot &>/dev/null; then
        run_task "Revoking $main at Let's Encrypt" certbot revoke --cert-path "${dir}fullchain.pem" --key-path "${dir}privkey.pem" \
            --non-interactive --no-delete-after-revoke
    else
        warn "Neither acme.sh nor certbot knows this certificate, it cannot be revoked from here"
        return 1
    fi
}

remove_cert_dir() {
    local dir=$1 main
    main=$(basename "$dir")
    cert_engines "$main"
    [ "$HAS_ACME" -eq 1 ] && run_task "Removing $main from acme.sh" _remove_acme_entry "$main"
    [ "$HAS_CERTBOT" -eq 1 ] && run_task "Removing $main from certbot" certbot delete --cert-name "$main" --non-interactive
    rm -f "${dir}privkey.pem" "${dir}fullchain.pem"
    rmdir "$dir" 2>/dev/null
    reg_del "$dir"
    success "Deleted $dir"
}

wizard_remove() {
    local dir main
    section "Remove a certificate"
    pick_cert || return 1
    dir=$SEL_DIR
    main=$(basename "$dir")
    cert_engines "$main"
    printf '\n'
    warn "This will:"
    hint "delete ${dir}privkey.pem and ${dir}fullchain.pem"
    [ "$HAS_ACME" -eq 1 ] && hint "remove $main from acme.sh and stop its auto-renew"
    [ "$HAS_CERTBOT" -eq 1 ] && hint "delete $main from certbot and stop its auto-renew"
    hint "A panel that still points to these files will fail to start until it gets a new certificate."
    printf '\n'
    if ! confirm "Remove the certificate for $main?"; then
        log "Nothing was removed"
        return 1
    fi
    printf '\n'
    hint "Revoking tells Let's Encrypt the certificate must no longer be trusted."
    hint "You only need it if the private key leaked or the domain changed owner."
    if confirm_optional "Also revoke it at Let's Encrypt?"; then
        printf '\n'
        revoke_cert "$dir"
    fi
    printf '\n'
    remove_cert_dir "$dir"
}

_uninstall_acme() {
    "$ACME" --uninstall
    rm -rf "${ACME_HOME:?}"
    return 0
}

_uninstall_certbot() {
    if command -v apt-get &>/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get remove -y certbot
    elif command -v dnf &>/dev/null; then
        dnf remove -y certbot
    elif command -v yum &>/dev/null; then
        yum remove -y certbot
    fi
    rm -rf /etc/letsencrypt
    return 0
}

yes_no_text() {
    if [ "$1" -eq 1 ]; then printf '%s' "$2"; else printf '%s' "$3"; fi
}

wizard_uninstall() {
    local del_certs=0 del_acme=0 del_certbot=0 d v reg_dirs=()
    section "Uninstall VESSL"
    printf '\n'
    if [ -r "$REGISTRY_FILE" ]; then
        while IFS= read -r d; do
            [ -n "$d" ] && [ -f "${d}fullchain.pem" ] && reg_dirs+=("$d")
        done < <(cut -d'|' -f3 "$REGISTRY_FILE")
    fi
    log "Always removed:"
    hint "$INSTALL_PATH"
    hint "$CONFIG_DIR  (settings and certificate list)"
    hint "$LOG_FILE"
    printf '\n'
    log "Optional, the default is to keep them:"
    if [ ${#reg_dirs[@]} -gt 0 ]; then
        confirm_optional "Delete the ${#reg_dirs[@]} certificate(s) issued with VESSL and stop their auto-renew?" && del_certs=1
    fi
    if [ -d "$ACME_HOME" ]; then
        confirm_optional "Uninstall acme.sh? Every certificate it manages stops renewing." && del_acme=1
    fi
    if command -v certbot &>/dev/null || [ -d /etc/letsencrypt ]; then
        confirm_optional "Remove certbot and /etc/letsencrypt? Certificates of other tools stored there are lost too." && del_certbot=1
    fi

    printf '\n'
    box_top "Uninstall plan"
    box_kv "VESSL" "remove"
    box_kv "Certificates" "$(yes_no_text "$del_certs" "delete ${#reg_dirs[@]}" "keep")"
    box_kv "acme.sh" "$(yes_no_text "$del_acme" "uninstall" "keep")"
    box_kv "certbot" "$(yes_no_text "$del_certbot" "remove, with /etc/letsencrypt" "keep")"
    box_bottom
    printf '\n'
    if [ "$ASSUME_YES" -eq 0 ]; then
        if [ ! -t 0 ]; then
            error "Run with -y to uninstall without a terminal"
            return 1
        fi
        v=$(ask "Type 'uninstall' to confirm") || return 1
        if [ "$v" != "uninstall" ]; then
            log "Cancelled, nothing was removed"
            return 1
        fi
    fi
    printf '\n'
    if [ "$del_certs" -eq 1 ]; then
        for d in "${reg_dirs[@]}"; do remove_cert_dir "$d"; done
    fi
    [ "$del_acme" -eq 1 ] && [ -d "$ACME_HOME" ] && run_task "Uninstalling acme.sh" _uninstall_acme
    [ "$del_certbot" -eq 1 ] && run_task "Removing certbot" _uninstall_certbot
    rm -f "$INSTALL_PATH"
    rm -rf "$CONFIG_DIR"
    [ -n "$LAST_OUTPUT" ] && rm -f "$LAST_OUTPUT"
    LAST_OUTPUT=""
    rm -f "$LOG_FILE"
    success "VESSL has been removed"
    hint "Shared tools such as curl, socat, openssl, dig and cron were left in place."
    printf '\n  %s\n\n' "${gray}Thanks for using VESSL.${reset}"
    support_box
    printf '\n'
    exit 0
}

menu_settings() {
    local c
    while true; do
        update_width
        clear_screen
        banner
        section "Settings"
        printf '\n'
        printf '  %s  %s%s\n' "$(col "${cyan}${bold}[1]${reset}" 5)" "$(col "Default email" 22)" "${DEFAULT_EMAIL:-${gray}not set${reset}}"
        printf '  %s  %s%s\n' "$(col "${cyan}${bold}[2]${reset}" 5)" "$(col "Default destination" 22)" "$(dest_text "$DEFAULT_DEST")"
        if [ "$CONFIG_VERBOSE" = "1" ]; then
            printf '  %s  %s%s\n' "$(col "${cyan}${bold}[3]${reset}" 5)" "$(col "Verbose output" 22)" "${green}on${reset} ${gray}show raw acme.sh / certbot output${reset}"
        else
            printf '  %s  %s%s\n' "$(col "${cyan}${bold}[3]${reset}" 5)" "$(col "Verbose output" 22)" "${gray}off${reset}"
        fi
        printf '  %s  %s%s\n' "$(col "${cyan}${bold}[4]${reset}" 5)" "$(col "Show recent log" 22)" "${gray}$LOG_FILE${reset}"
        printf '  %s  %s\n\n' "$(col "${cyan}${bold}[0]${reset}" 5)" "Back"
        c=$(ask "Select") || return 0
        case "$c" in
            1)
                printf '\n'
                if ask_email; then
                    DEFAULT_EMAIL=$email
                    save_config && success "Saved"
                    sleep 1
                fi
                ;;
            2)
                DOMAINS=()
                if pick_destination; then
                    DEFAULT_DEST=$DEST_TARGET
                    save_config && success "Saved"
                    sleep 1
                fi
                ;;
            3)
                if [ "$CONFIG_VERBOSE" = "1" ]; then
                    CONFIG_VERBOSE=0
                    VERBOSE=$CLI_VERBOSE
                else
                    CONFIG_VERBOSE=1
                    VERBOSE=1
                fi
                save_config
                ;;
            4)
                printf '\n'
                if [ -s "$LOG_FILE" ]; then
                    tail -n 40 "$LOG_FILE" | sed 's/\x1b\[[0-9;]*m//g; s/^/  /'
                else
                    warn "The log is empty"
                fi
                pause
                ;;
            0|q|"") return 0 ;;
        esac
    done
}

version_gt() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" = "$1" ]
}

menu_update() {
    local tmp remote="" self installed=""
    section "Update VESSL"
    printf '\n'
    self=$(readlink -f "$0" 2>/dev/null)
    [ -f "$INSTALL_PATH" ] && installed=$(grep -m1 '^VERSION=' "$INSTALL_PATH" | cut -d'"' -f2)
    tmp=$(mktemp)
    if run_task -q "Checking GitHub" curl -fsSL --max-time 20 -o "$tmp" "$RAW_URL" && bash -n "$tmp" 2>/dev/null; then
        remote=$(grep -m1 '^VERSION=' "$tmp" | cut -d'"' -f2)
    fi
    box_top "Versions"
    box_kv "Running" "v$VERSION"
    if [ -n "$installed" ]; then
        box_kv "Installed" "v$installed · $INSTALL_PATH"
    else
        box_kv "Installed" "no"
    fi
    box_kv "Latest" "${remote:+v$remote}${remote:-unavailable}"
    box_kv "Repo" "$REPO_URL"
    box_bottom
    printf '\n'
    if [ -z "$remote" ]; then
        error "Could not download $RAW_URL"
        if [ -f "$self" ] && [ "$self" != "$INSTALL_PATH" ] && confirm "Install this running copy (v$VERSION) to $INSTALL_PATH instead?"; then
            install -m 755 "$self" "$INSTALL_PATH" && success "Installed. Run it with: vessl"
        fi
        rm -f "$tmp"
        return 1
    fi
    if [ -n "$installed" ] && ! version_gt "$remote" "$installed"; then
        success "You already have the latest version"
        rm -f "$tmp"
        return 0
    fi
    if confirm "Install v$remote to $INSTALL_PATH?"; then
        if install -m 755 "$tmp" "$INSTALL_PATH"; then
            success "VESSL v$remote installed. Run it with: vessl"
            rm -f "$tmp"
            if confirm "Restart VESSL now?"; then
                [ -n "$LAST_OUTPUT" ] && rm -f "$LAST_OUTPUT"
                exec "$INSTALL_PATH"
            fi
            return 0
        fi
        error "Could not write $INSTALL_PATH"
    fi
    rm -f "$tmp"
}

status_box() {
    local host ip acme_s cb_s cf_s users p80 n soon=0 d certs_s
    host=$(hostname -s 2>/dev/null || hostname)
    ip=${SERVER_IPV4:-${SERVER_IPV6:-unknown}}
    if [ -x "$ACME" ]; then acme_s="${green}✓${reset} acme.sh"; else acme_s="${red}✗${reset} acme.sh"; fi
    if command -v certbot &>/dev/null; then cb_s="${green}✓${reset} certbot"; else cb_s="${red}✗${reset} certbot"; fi
    if cf_saved; then cf_s="${green}●${reset} saved"; else cf_s="${gray}● not set${reset}"; fi
    users=$(port_users 80)
    if [ -z "$users" ]; then
        p80="${green}●${reset} free"
    else
        p80="${orange}●${reset} $(fit "$users" 18)"
    fi
    collect_certs
    n=${#CERT_DIRS[@]}
    for d in "${CERT_DIRS[@]}"; do
        if cert_info "${d}fullchain.pem" && ((C_DAYS < 15)); then soon=$((soon + 1)); fi
    done
    certs_s="$n found"
    ((soon > 0)) && certs_s+=" · ${orange}$soon expiring${reset}"
    box_top "Server"
    box_row "$(col "${gray}Host${reset}" 10)$(col "$(fit "$host" 20)" 22)$(col "${gray}IP${reset}" 12)$ip"
    box_row "$(col "${gray}Engines${reset}" 10)$(col "$acme_s  $cb_s" 22)$(col "${gray}Port 80${reset}" 12)$p80"
    box_row "$(col "${gray}Certs${reset}" 10)$(col "$certs_s" 22)$(col "${gray}Cloudflare${reset}" 12)$cf_s"
    box_bottom
}

menu_item() {
    printf '  %s  %s%s\n' "$(col "${cyan}${bold}$1${reset}" 5)" "$(col "$2" 28)" "${gray}$3${reset}"
}

installed_version() {
    [ -f "$INSTALL_PATH" ] || return 1
    grep -m1 '^VERSION=' "$INSTALL_PATH" 2>/dev/null | cut -d'"' -f2
}

_download_self() {
    curl -fsSL --max-time 30 -o "$1" "$RAW_URL" && bash -n "$1"
}

ensure_installed() {
    local have self tmp
    self=$(readlink -f "$0" 2>/dev/null)
    [ "$self" = "$INSTALL_PATH" ] && return 0
    have=$(installed_version)
    if [ -n "$have" ] && ! version_gt "$VERSION" "$have"; then
        return 0
    fi
    tmp=$(mktemp)
    if [ -f "$self" ] && grep -q '^VERSION=' "$self" 2>/dev/null; then
        cp "$self" "$tmp"
    elif [[ "${BASH_EXECUTION_STRING:-}" == *'VERSION="'* ]]; then
        printf '%s\n' "$BASH_EXECUTION_STRING" > "$tmp"
    elif ! run_task -q "Installing the vessl command" _download_self "$tmp"; then
        rm -f "$tmp"
        MENU_NOTICE="${orange}⚠${reset} Could not install the ${bold}vessl${reset} command. Install it with: ${bold}curl -fsSL $RAW_URL -o $INSTALL_PATH && chmod +x $INSTALL_PATH${reset}"
        return 1
    fi
    if bash -n "$tmp" 2>/dev/null && install -m 755 "$tmp" "$INSTALL_PATH"; then
        if [ -n "$have" ]; then
            MENU_NOTICE="${green}✓${reset} The ${bold}vessl${reset} command was updated from v$have to v$VERSION"
        else
            MENU_NOTICE="${green}✓${reset} VESSL is installed. Next time just type ${bold}vessl${reset}"
        fi
    else
        MENU_NOTICE="${orange}⚠${reset} Could not write $INSTALL_PATH"
    fi
    rm -f "$tmp"
}

run_menu() {
    local c
    require_root
    load_config
    printf '\n'
    ensure_installed
    detect_ips
    while true; do
        restore_services
        clear_secrets
        FORCE=0
        RUN_TEST=0
        SKIP_CHECK=0
        WILDCARD=0
        DNS_METHOD=""
        DOMAINS=()
        email=""
        destination=""
        DEST_TARGET=""
        update_width
        clear_screen
        banner
        status_box
        if [ -n "$MENU_NOTICE" ]; then
            printf '\n  %s\n' "$MENU_NOTICE"
            MENU_NOTICE=""
        fi
        printf '\n'
        menu_item "[1]" "Issue certificate" "one or more domains, HTTP"
        menu_item "[2]" "Issue wildcard certificate" "*.domain, DNS"
        menu_item "[3]" "Check domain" "preflight + staging test"
        menu_item "[4]" "Show ports" "who is listening where"
        menu_item "[5]" "My certificates" "list with expiry"
        menu_item "[6]" "Renew certificate" "force renew an existing one"
        menu_item "[7]" "Remove certificate" "delete, revoke, stop renew"
        menu_item "[8]" "Settings" "defaults and log"
        menu_item "[9]" "Update VESSL" "install or update from GitHub"
        menu_item "[10]" "Uninstall VESSL" "remove VESSL from this server"
        menu_item "[0]" "Exit" ""
        printf '\n'
        support_line
        printf '\n'
        read -r -p "  ${cyan}❯${reset} Select an option: " c || {
            printf '\n'
            exit 0
        }
        case "$c" in
            1) wizard_issue; pause ;;
            2) wizard_wildcard; pause ;;
            3) wizard_check; pause ;;
            4) show_ports; pause ;;
            5)
                section "My certificates"
                printf '\n'
                print_cert_list
                pause
                ;;
            6) wizard_renew; pause ;;
            7) wizard_remove; pause ;;
            8) menu_settings ;;
            9) menu_update; pause ;;
            10) wizard_uninstall; pause ;;
            0|q|Q|exit)
                printf '\n  %s\n\n' "${gray}Bye. See you on YouTube: ${YOUTUBE_URL}${reset}"
                exit 0
                ;;
        esac
    done
}

cli_issue() {
    local target
    require_root
    load_config
    if [ $# -lt 3 ]; then
        error "Not enough arguments. Run 'vessl --help' for usage."
        exit 1
    fi
    email=$1
    shift
    validate_email "$email" || exit 1
    target=${!#}
    WILDCARD=0
    prepare_domains "${@:1:$#-1}" || exit 1
    resolve_destination "$target" || exit 1
    [ "$IS_TTY" -eq 1 ] && banner
    show_plan
    do_issue || exit 1
}

cli_wildcard() {
    require_root
    load_config
    if [ $# -ne 3 ]; then
        error "Usage: vessl --wildcard <email> <domain> <destination> [--cf-token T | --cf-key K --cf-email E | --manual]"
        exit 1
    fi
    email=$1
    validate_email "$email" || exit 1
    prepare_wildcard "$2" || exit 1
    resolve_destination "$3" || exit 1
    if [ -z "$DNS_METHOD" ]; then
        if [ -n "${CF_Token:-}" ]; then
            DNS_METHOD="cf_token"
            CF_TOKEN_IN=$CF_Token
        elif [ -n "${CF_Key:-}" ] && [ -n "${CF_Email:-}" ]; then
            DNS_METHOD="cf_key"
            CF_KEY_IN=$CF_Key
            CF_EMAIL_IN=$CF_Email
        elif cf_saved; then
            DNS_METHOD="cf_saved"
        elif [ -t 0 ]; then
            { pick_dns_method && ask_cf_credentials; } || exit 1
        else
            error "Choose a validation method: --cf-token, --cf-key with --cf-email, or --manual"
            exit 1
        fi
    fi
    if [ "$DNS_METHOD" = "cf_token" ] && [ -z "$CF_TOKEN_IN" ]; then
        error "--cf-token needs a value"
        exit 1
    fi
    if [ "$DNS_METHOD" = "cf_key" ]; then
        [ -n "$CF_EMAIL_IN" ] || CF_EMAIL_IN=${CF_Email:-}
        if [ -z "$CF_KEY_IN" ] || [ -z "$CF_EMAIL_IN" ]; then
            error "--cf-key needs a value and --cf-email <cloudflare account email>"
            exit 1
        fi
    fi
    [ "$IS_TTY" -eq 1 ] && banner
    show_plan
    do_issue_dns || exit 1
}

cli_check() {
    require_root
    load_config
    if [[ "$1" == *@* ]]; then
        email=$1
        validate_email "$email" || exit 1
        shift
    else
        email=$DEFAULT_EMAIL
    fi
    if [ $# -lt 1 ]; then
        error "Usage: vessl --check [email] <domain1> [domain2 ...]"
        exit 1
    fi
    WILDCARD=0
    prepare_domains "$@" || exit 1
    [ "$IS_TTY" -eq 1 ] && banner
    run_check_flow
    exit $?
}

cli_install() {
    local src
    src=$(readlink -f "$0" 2>/dev/null)
    if [ -f "$src" ] && [ "$src" != "$INSTALL_PATH" ]; then
        install -m 755 "$src" "$INSTALL_PATH" && success "VESSL installed to $INSTALL_PATH. Run it with: vessl"
        return
    fi
    cli_update
}

cli_update() {
    local tmp
    tmp=$(mktemp)
    if run_task "Downloading VESSL from GitHub" curl -fsSL --max-time 30 -o "$tmp" "$RAW_URL" && bash -n "$tmp" 2>/dev/null; then
        install -m 755 "$tmp" "$INSTALL_PATH" && success "VESSL v$(grep -m1 '^VERSION=' "$tmp" | cut -d'"' -f2) installed to $INSTALL_PATH"
    else
        error "Download failed or the downloaded file is not a valid script"
        hint "$RAW_URL"
    fi
    rm -f "$tmp"
}

show_version() {
    printf '%s\n' "${cyan}${bold}VESSL${reset} v$VERSION · $APP_TAGLINE"
    printf '%s\n' "${gray}Forked from $UPSTREAM_NAME · $UPSTREAM_URL${reset}"
    printf '%s\n\n' "${gray}$REPO_URL${reset}"
    support_box
}

show_help() {
    cat << EOF

${cyan}${bold}VESSL${reset} v$VERSION · $APP_TAGLINE
${gray}Forked from $UPSTREAM_NAME ($UPSTREAM_URL)${reset}

${bold}Usage${reset}
  vessl                                          open the interactive menu
  vessl <email> <domain...> <destination> [options]
  vessl --wildcard <email> <domain> <destination> [dns options]
  vessl --check [email] <domain...>
  vessl --ports | --list
  vessl --install | --update | --uninstall | --help | --version

${bold}Destination${reset}
  Panels   marzban, marzneshin, pasarguard, rebecca, x-ui, 3x-ui, s-ui, hiddify, ovpanel
  Custom   an absolute path. A trailing slash is optional:
           /root/certs and /root/certs/ are the same.
  A folder named after the first domain is created inside it:
           /root/certs  →  /root/certs/example.com/privkey.pem
                           /root/certs/example.com/fullchain.pem

${bold}Options${reset}
  --test          Run a staging test before the real request (HTTP only)
  --skip-check    Skip the preflight checks
  --force         Renew even if the current certificate is still valid
  --verbose       Show raw acme.sh / certbot output
  -y, --yes       Answer yes to every prompt
  --purge         With --uninstall: also delete certificates, acme.sh and certbot

${bold}Wildcard DNS options${reset}
  --cf-token <token>                 Cloudflare API token (recommended)
  --cf-key <key> --cf-email <email>  Cloudflare Global API Key
  --manual                           Show TXT records to add by hand (needs a terminal)
  The CF_Token, or CF_Key and CF_Email, environment variables also work.
  Without any of these, Cloudflare credentials saved in acme.sh are used.

${bold}Commands${reset}
  -m, --menu        Open the interactive menu
  -w, --wildcard    Issue a wildcard certificate for domain and *.domain
  -c, --check       Preflight checks + staging test, nothing real is issued
  -p, --ports       Show listening TCP ports and who owns them
  -l, --list        Show certificates and their expiry
  -u, --update      Download the latest VESSL from GitHub
  --install         Install VESSL to $INSTALL_PATH
  --uninstall       Remove VESSL from this server
  -h, --help        Show this help
  -v, --version     Show version

${bold}Examples${reset}
  vessl
  vessl --check example.com www.example.com
  vessl user@example.com example.com marzban
  vessl user@example.com example.com www.example.com /root/certs --test
  vessl --wildcard user@example.com example.com marzban --cf-token XXXX
  CF_Token=XXXX vessl --wildcard user@example.com example.com /root/certs -y
  vessl --wildcard user@example.com example.com 3x-ui --manual
  vessl --uninstall

${bold}Install${reset}
  curl -fsSL $RAW_URL -o $INSTALL_PATH && chmod +x $INSTALL_PATH

${bold}Support VESSL${reset}
  ${yellow}★${reset} Star it on GitHub      $REPO_URL
  ${ytred}▶${reset} Subscribe on YouTube   $YOUTUBE_URL  ($YOUTUBE_NAME)

Logs: $LOG_FILE
Must be run as root.

EOF
}

main() {
    local args=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -y|--yes) ASSUME_YES=1 ;;
            --purge) PURGE=1 ;;
            --test) RUN_TEST=1 ;;
            --skip-check) SKIP_CHECK=1 ;;
            --force) FORCE=1 ;;
            --verbose) CLI_VERBOSE=1 ;;
            --manual) DNS_METHOD="manual" ;;
            --cf-token)
                DNS_METHOD="cf_token"
                CF_TOKEN_IN=${2:-}
                [ $# -gt 1 ] && shift
                ;;
            --cf-key)
                DNS_METHOD="cf_key"
                CF_KEY_IN=${2:-}
                [ $# -gt 1 ] && shift
                ;;
            --cf-email)
                CF_EMAIL_IN=${2:-}
                [ $# -gt 1 ] && shift
                ;;
            *) args+=("$1") ;;
        esac
        shift
    done
    set -- "${args[@]}"
    setup_locale
    setup_colors
    setup_log
    VERBOSE=$CLI_VERBOSE

    case "${1:-}" in
        "")
            if [ -t 0 ] && [ -t 1 ]; then
                run_menu
            else
                show_help
            fi
            ;;
        -m|--menu) run_menu ;;
        -w|--wildcard)
            shift
            cli_wildcard "$@"
            ;;
        -c|--check)
            shift
            cli_check "$@"
            ;;
        -p|--ports) show_ports ;;
        -l|--list)
            require_root
            section "My certificates"
            printf '\n'
            print_cert_list
            ;;
        -u|--update|--upgrade)
            require_root
            cli_update
            ;;
        --install)
            require_root
            cli_install
            ;;
        --uninstall)
            require_root
            wizard_uninstall
            ;;
        -h|--help) show_help ;;
        -v|--version) show_version ;;
        -*)
            error "Unknown option: $1"
            hint "Run 'vessl --help' for usage."
            exit 1
            ;;
        *) cli_issue "$@" ;;
    esac
}

main "$@"
