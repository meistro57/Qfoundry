#!/bin/bash
set -e
trap 'echo -e "${RED}[!] Forge aborted at line $LINENO.${NC}"' ERR

# --- Colors ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- Initial State ---
INSTALL_SYSTEM=true
INSTALL_SKELETON=true
INJECT_OVERSEER=true
CREATE_START_SCRIPT=true
RESET_FORGE=false
FORGE_MANIFEST=".qfoundry-forge.manifest"

INSTALL_PRISM=true
INSTALL_NEURON=true
INSTALL_OPENROUTER=true
INSTALL_GEMINI=true

INSTALL_FLUENTVOX=true
INSTALL_PYTHON_VENV=true
INSTALL_PYTORCH=false

INSTALL_RECTOR=true
INSTALL_PLAYWRIGHT=true

INSTALL_TOON=true
INSTALL_AUTOCRUD=true
INSTALL_SEEDER_GENERATOR=true
INSTALL_CHIMIT_PROMPT=true

INSTALL_CREDITS=true
INSTALL_HYDEPHP=true
INSTALL_ALTITUDE=false
ALTITUDE_MODE="tall"
RUN_MASTER_CLEANUP=false

INSTALL_SOLO=true
INSTALL_WHISP=true

toggle_var() {
    local var=$1
    local current
    current=$(eval "echo \$$var")
    if [[ "$current" == "true" ]]; then
        eval "$var=false"
    else
        eval "$var=true"
    fi
}

detect_gpu() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        return 0
    fi
    if [[ -d /proc/driver/nvidia/gpus ]]; then
        return 0
    fi
    return 1
}

record_path() {
    local path=$1
    echo "$path" >> "$FORGE_MANIFEST"
}

on_off() {
    local var=$1
    if [[ "$(eval "echo \$$var")" == "true" ]]; then
        echo -e "${GREEN}[ON]${NC}"
    else
        echo -e "${RED}[OFF]${NC}"
    fi
}

composer_run() {
    local composer_bin
    composer_bin=$(command -v composer)
    export COMPOSER_ALLOW_SUPERUSER=1
    export COMPOSER_NO_SCRIPTS=1
    export COMPOSER_NO_INTERACTION=1
    local args=("$@")
    local has_no_scripts=false
    for arg in "${args[@]}"; do
        if [[ "$arg" == "--no-scripts" ]]; then
            has_no_scripts=true
            break
        fi
    done
    if [[ "$has_no_scripts" == "false" ]]; then
        args+=("--no-scripts")
    fi
    if [[ -n "$composer_bin" ]] && head -n1 "$composer_bin" | grep -q "php"; then
        php -d error_reporting=0 -d display_errors=0 -d log_errors=0 "$composer_bin" "${args[@]}" 2> >(grep -v -E '^(Deprecation Notice|Deprecated:)' >&2 || true)
    else
        composer "${args[@]}" 2> >(grep -v -E '^(Deprecation Notice|Deprecated:)' >&2 || true)
    fi
}

install_pkg() {
    local pkg=$1
    local is_dev=$2
    if [[ "$is_dev" == "true" ]]; then
        composer_run require "$pkg" --dev -W --ignore-platform-reqs --quiet
    else
        composer_run require "$pkg" -W --ignore-platform-reqs --quiet
    fi
}

render_menu() {
    clear
    echo -e "${CYAN}╭────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC}${YELLOW}          QFOUNDRY: IMPERIAL FORGE          ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
    echo -e "${PURPLE}Arrows/jk: move  Space: toggle  M: mode  S: ship  Q: quit${NC}\n"

    for i in "${!ITEM_TYPE[@]}"; do
        local cursor=" "
        [[ $i -eq $SELECTED ]] && cursor="›"
        if [[ "${ITEM_TYPE[$i]}" == "section" ]]; then
            echo -e "${CYAN}┌────────────────────────────────────────────────┐${NC}"
            printf "%s ${CYAN}│${NC} ${YELLOW}%-46s${NC} ${CYAN}│${NC}\n" "$cursor" "${ITEM_LABEL[$i]}"
            echo -e "${CYAN}└────────────────────────────────────────────────┘${NC}"
        else
            local state
            state=$(on_off "${ITEM_VAR[$i]}")
            printf "%s  %s  %-40s\n" "$cursor" "$state" "${ITEM_LABEL[$i]}"
        fi
    done

    if [[ "$ALTITUDE_MODE" == "tall" ]]; then
        echo -e "\n${BLUE}Altitude mode:${NC} TALL (Altitude)"
    else
        echo -e "\n${BLUE}Altitude mode:${NC} Nuxt 3 + Nuxt UI"
    fi

    if detect_gpu; then
        echo -e "${GREEN}GPU:${NC} detected (PyTorch auto)"
    else
        echo -e "${YELLOW}GPU:${NC} not detected"
    fi
}

is_toggleable() {
    [[ "${ITEM_TYPE[$1]}" == "option" ]]
}

next_index() {
    local step=$1
    local i=$SELECTED
    local count=${#ITEM_TYPE[@]}
    i=$(( (i + step + count) % count ))
    SELECTED=$i
}

ITEM_TYPE=(
    section option option option option option option
    section option option option option
    section option option option
    section option option
    section option option option option
    section option option option
    section option option
)

ITEM_LABEL=(
    "CORE" "System packages (PHP, tools)" "Laravel starter kit" "Inject Overseer agent" "Create start.sh" "Master Forge cleanup" "Start over (remove artifacts)"
    "BRAIN" "Prism" "Neuron" "OpenRouter" "Gemini Multimodal"
    "VOICE" "FluentVox package" "Python venv" "PyTorch (GPU auto)"
    "GUARD" "Rector" "Playwright"
    "EFFICIENCY" "TOON (Token Compression)" "Auto-CRUD Scaffolding" "Seeder Generator" "Chimit/Prompt"
    "ECONOMY" "Climactic Credits" "HydePHP" "Altitude / Nuxt UI"
    "COCKPIT" "Solo" "Whisp"
)

ITEM_VAR=(
    "" "INSTALL_SYSTEM" "INSTALL_SKELETON" "INJECT_OVERSEER" "CREATE_START_SCRIPT" "RUN_MASTER_CLEANUP" "RESET_FORGE"
    "" "INSTALL_PRISM" "INSTALL_NEURON" "INSTALL_OPENROUTER" "INSTALL_GEMINI"
    "" "INSTALL_FLUENTVOX" "INSTALL_PYTHON_VENV" "INSTALL_PYTORCH"
    "" "INSTALL_RECTOR" "INSTALL_PLAYWRIGHT"
    "" "INSTALL_TOON" "INSTALL_AUTOCRUD" "INSTALL_SEEDER_GENERATOR" "INSTALL_CHIMIT_PROMPT"
    "" "INSTALL_CREDITS" "INSTALL_HYDEPHP" "INSTALL_ALTITUDE"
    "" "INSTALL_SOLO" "INSTALL_WHISP"
)

SELECTED=0

# --- Interactive Cockpit ---
while true; do
    render_menu
    IFS= read -rsn1 key
    case "$key" in
        $'\x1b')
            IFS= read -rsn2 key
            case "$key" in
                "[A") next_index -1 ;;
                "[B") next_index 1 ;;
            esac
            ;;
        j) next_index 1 ;;
        k) next_index -1 ;;
        " ")
            if is_toggleable "$SELECTED"; then
                toggle_var "${ITEM_VAR[$SELECTED]}"
            fi
            ;;
        [Mm])
            if [[ "$ALTITUDE_MODE" == "tall" ]]; then
                ALTITUDE_MODE="nuxt"
            else
                ALTITUDE_MODE="tall"
            fi
            ;;
        [Ss]) break ;;
        [Qq]) exit ;;
    esac
done

echo -e "\n${GREEN}[*] Ignition confirmed. Forging the Empire...${NC}"
[[ $EUID -ne 0 ]] && sudo -v

# --- Stage 1: System & Skeleton ---
if [[ $RESET_FORGE == true ]]; then
    echo -e "${RED}[!] Starting over: removing prior forge artifacts...${NC}"
    if [[ -f "$FORGE_MANIFEST" ]]; then
        while IFS= read -r path; do
            [[ -z "$path" ]] && continue
            rm -rf "$path"
        done < "$FORGE_MANIFEST"
        rm -f "$FORGE_MANIFEST"
    else
        rm -rf venv frontend start.sh bin/overseer-ssh
        rm -rf vendor node_modules
        rm -f composer.lock package-lock.json pnpm-lock.yaml yarn.lock bun.lockb
        rm -f app/Foundry/Agents/Overseer.php
        rm -rf app/Foundry/Agents
        rm -rf resources/prompts
    fi
fi
if [[ $INSTALL_SYSTEM == true ]]; then
    echo -e "${BLUE}[1/5] Tempering PHP 8.4 & System Packages...${NC}"
    sudo apt-get update -y && sudo apt-get install -y php8.4 php8.4-cli php8.4-{curl,mbstring,xml,bcmath,sqlite3,zip,intl} python3-venv libffi-dev libsodium-dev unzip git curl --quiet
fi

if [[ $INSTALL_SKELETON == true ]]; then
    rm -rf qfoundry_tmp
    composer_run create-project nunomaduro/laravel-starter-kit qfoundry_tmp --prefer-dist --quiet --no-scripts
    cp -r --update=none qfoundry_tmp/{*,.*} . || true
    rm -rf qfoundry_tmp
fi

# --- Stage 2: The Infusion ---

if [[ $INSTALL_PRISM == true ]]; then
    echo -e "${BLUE}[+] Infusing Prism...${NC}"
    install_pkg "prism-php/prism:^0.99" "false"
fi
if [[ $INSTALL_NEURON == true ]]; then
    echo -e "${BLUE}[+] Infusing Neuron...${NC}"
    install_pkg "neuron-core/neuron-laravel:^0.3" "false"
fi
if [[ $INSTALL_OPENROUTER == true ]]; then
    echo -e "${BLUE}[+] Infusing OpenRouter...${NC}"
    install_pkg "moe-mizrak/laravel-openrouter" "false"
    if [[ -f artisan ]]; then
        php artisan vendor:publish --provider="MoeMizrak\\LaravelOpenRouter\\LaravelOpenRouterServiceProvider"
    fi
fi
if [[ $INSTALL_GEMINI == true ]]; then
    echo -e "${BLUE}[+] Infusing Gemini Multimodal...${NC}"
    install_pkg "hosseinhezami/laravel-gemini" "false"
    if [[ -f artisan ]]; then
        php artisan vendor:publish --tag=gemini-config
    fi
fi
if [[ $INSTALL_FLUENTVOX == true ]]; then
    echo -e "${PURPLE}[+] Infusing FluentVox...${NC}"
    if ! composer_run require "b7s/fluentvox:^1.0" -W --ignore-platform-reqs; then
        echo -e "${RED}[!] FluentVox install failed. Re-running with verbose output...${NC}"
        composer_run -vvv require "b7s/fluentvox:^1.0" -W --ignore-platform-reqs || true
        exit 1
    fi
fi
if [[ $INSTALL_PYTHON_VENV == true ]]; then
    python3 -m venv venv
    ./venv/bin/pip install --upgrade pip --quiet
    record_path "venv"
fi
if [[ $INSTALL_PYTORCH == true ]] || detect_gpu; then
    if [[ -x ./vendor/bin/fluentvox ]]; then
        if ! ./vendor/bin/fluentvox install --pytorch --quiet; then
            echo -e "${YELLOW}[-] FluentVox PyTorch install failed. Skipping PyTorch setup.${NC}"
        fi
    else
        echo -e "${YELLOW}[-] FluentVox binary not found at ./vendor/bin/fluentvox. Skipping PyTorch setup.${NC}"
    fi
fi
if [[ $INSTALL_SOLO == true ]]; then
    echo -e "${YELLOW}[+] Forging Solo...${NC}"
    install_pkg "soloterm/solo:^0.5" "false"
    if php artisan list 2>/dev/null | grep -q "solo:install"; then
        php artisan solo:install --quiet || {
            echo -e "${YELLOW}[-] solo:install failed. Skipping.${NC}"
        }
    else
        echo -e "${YELLOW}[-] solo:install not available. Skipping install step.${NC}"
    fi
fi
if [[ $INSTALL_WHISP == true ]]; then
    echo -e "${YELLOW}[+] Forging Whisp...${NC}"
    install_pkg "whispphp/whisp:^2.0" "false"
fi
if [[ $INSTALL_RECTOR == true ]]; then
    echo -e "${CYAN}[+] Activating Rector...${NC}"
    install_pkg "rector/rector:^2.0" "true"
fi
if [[ $INSTALL_PLAYWRIGHT == true ]]; then
    echo -e "${CYAN}[+] Activating Playwright...${NC}"
    if [[ -f composer.json ]] && rg -n "\"laravel/framework\"\\s*:\\s*\"[^\"]*12" composer.json >/dev/null 2>&1; then
        echo -e "${YELLOW}[-] Playwright package does not support Laravel 12. Skipping.${NC}"
    else
        if ! composer_run require "web-id/laravel-playwright:dev-main" --dev -W --ignore-platform-reqs; then
            echo -e "${YELLOW}[-] Playwright install failed. Re-running with verbose output...${NC}"
            composer_run -vvv require "web-id/laravel-playwright:dev-main" --dev -W --ignore-platform-reqs || true
            echo -e "${YELLOW}[-] Skipping Playwright.${NC}"
        fi
    fi
fi
if [[ $INSTALL_TOON == true ]]; then
    echo -e "${GREEN}[+] Adding TOON...${NC}"
    install_pkg "mischasigtermans/laravel-toon" "false"
fi
if [[ $INSTALL_AUTOCRUD == true ]]; then
    echo -e "${GREEN}[+] Adding Auto-CRUD...${NC}"
    install_pkg "mrmarchone/laravel-auto-crud" "false"
    if [[ -f artisan ]]; then
        if php artisan list 2>/dev/null | grep -q "auto-crud:install"; then
            php artisan auto-crud:install || {
                echo -e "${YELLOW}[-] auto-crud:install failed. Skipping.${NC}"
            }
        else
            echo -e "${YELLOW}[-] auto-crud:install not available. Skipping.${NC}"
        fi
    fi
fi
if [[ $INSTALL_SEEDER_GENERATOR == true ]]; then
    echo -e "${GREEN}[+] Adding Seeder Generator...${NC}"
    install_pkg "tyghaykal/laravel-seed-generator" "false"
    if [[ -f artisan ]]; then
        php artisan vendor:publish --tag=seed-generator-config
    fi
fi
if [[ $INSTALL_CHIMIT_PROMPT == true ]]; then
    echo -e "${GREEN}[+] Adding Chimit/Prompt...${NC}"
    install_pkg "chimit/prompt" "false"
    if [[ -f artisan ]]; then
        if php artisan list 2>/dev/null | rg -q "prompt:install"; then
            php artisan prompt:install || {
                echo -e "${YELLOW}[-] prompt:install failed. Skipping.${NC}"
            }
        else
            echo -e "${YELLOW}[-] prompt:install not available. Skipping.${NC}"
        fi
    fi
fi
if [[ $INSTALL_CREDITS == true ]]; then
    echo -e "${GREEN}[+] Adding Climactic Credits...${NC}"
    if ! composer_run require "climactic/laravel-credits" -W --ignore-platform-reqs; then
        echo -e "${YELLOW}[-] climactic/credits not found on Packagist. Skipping.${NC}"
    else
        if [[ -f artisan ]]; then
            if php artisan list 2>/dev/null | rg -q "vendor:publish"; then
                php artisan vendor:publish --tag="credits-migrations" || true
                php artisan vendor:publish --tag="credits-config" || true
            fi
            php artisan migrate
        fi
    fi
fi
if [[ $INSTALL_HYDEPHP == true ]]; then
    echo -e "${GREEN}[+] Adding HydePHP...${NC}"
    install_pkg "hyde/framework" "false"
    if [[ -f artisan ]]; then
        if php artisan list 2>/dev/null | rg -q "hyde:publish-configs"; then
            php artisan hyde:publish-configs || {
                echo -e "${YELLOW}[-] hyde:publish-configs failed. Skipping.${NC}"
            }
        else
            echo -e "${YELLOW}[-] hyde:publish-configs not available. Skipping.${NC}"
        fi
    fi
fi
if [[ $INSTALL_ALTITUDE == true ]]; then
    echo -e "${GREEN}[+] Adding Altitude / Nuxt UI...${NC}"
    if [[ "$ALTITUDE_MODE" == "tall" ]]; then
        install_pkg "livewire/livewire" "false"
        install_pkg "tailover/altitude" "false"
        if [[ -f artisan ]]; then
            php artisan altitude:install
        fi
    else
        if command -v npx >/dev/null 2>&1; then
            npx nuxi@latest init frontend
            if command -v bun >/dev/null 2>&1; then
                (cd frontend && bun add @nuxt/ui)
            else
                echo -e "${YELLOW}[-] bun not found. Skipping Nuxt UI install.${NC}"
            fi
            if [[ -f frontend/nuxt.config.ts ]]; then
                python3 - <<'PY'
from pathlib import Path
import re

p = Path("frontend/nuxt.config.ts")
txt = p.read_text()
if "@nuxt/ui" in txt:
    raise SystemExit(0)

m = re.search(r"modules\s*:\s*\[(.*?)\]", txt, re.S)
if m:
    inner = m.group(1).strip()
    prefix = "" if not inner else inner + ", "
    new = "modules: [" + prefix + "'@nuxt/ui']"
    txt = txt[:m.start()] + new + txt[m.end():]
else:
    m = re.search(r"defineNuxtConfig\\s*\\(\\s*\\{", txt)
    if not m:
        raise SystemExit(0)
    insert_at = m.end()
    txt = txt[:insert_at] + "\\n  modules: ['@nuxt/ui']," + txt[insert_at:]

p.write_text(txt)
PY
            else
                echo -e "${YELLOW}[-] frontend/nuxt.config.ts not found. Skipping module patch.${NC}"
            fi
        else
            echo -e "${YELLOW}[-] npx not found. Skipping Nuxt setup.${NC}"
        fi
    fi
fi

if [[ $RUN_MASTER_CLEANUP == true && -f artisan ]]; then
    echo -e "${BLUE}[+] Master Forge cleanup...${NC}"
    php artisan vendor:publish --all
    php artisan migrate
    composer_run dump-autoload
fi

# --- Stage 3: Sentience Injection ---
if [[ $INJECT_OVERSEER == true ]]; then
    echo -e "${BLUE}[3/5] Injecting Agentic Logic...${NC}"
    mkdir -p app/Foundry/Agents bin resources/prompts

    cat <<'EOF' > app/Foundry/Agents/Overseer.php
<?php
namespace App\Foundry\Agents;
use Prism\Prism;
class Overseer {
    public function command($prompt) {
        return Prism::text()->using('google', 'gemini-1.5-pro')->prompt($prompt)->generate()->text;
    }
}
EOF

    cat <<'EOF' > bin/overseer-ssh
<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';
use App\Foundry\Agents\Overseer;
use function Laravel\Prompts\{text, info, spin};
$overseer = new Overseer();
info('--- QFOUNDRY OVERSEER ---');
$input = text('Architect Command:');
$response = spin(fn() => $overseer->command($input), 'Reasoning...');
info("\nResponse:"); echo $response . PHP_EOL;
EOF
    chmod +x bin/overseer-ssh
    record_path "app/Foundry/Agents"
    record_path "bin/overseer-ssh"
    record_path "resources/prompts"
fi

# --- Stage 4: Ignition ---
if [[ $CREATE_START_SCRIPT == true ]]; then
    cat <<'EOF' > start.sh
#!/bin/bash
set -e
echo "Igniting Qfoundry SSH & Dashboard..."
if [[ -x bin/overseer-ssh && -f vendor/autoload.php ]]; then
  php -r "require 'vendor/autoload.php'; (new Whisp\\Server(port: 2222, autoDiscoverApps: false))->run(['default' => getcwd().'/bin/overseer-ssh']);" &
else
  echo "[-] Whisp app not found; skipping SSH server."
fi
if php artisan list 2>/dev/null | rg -q "solo"; then
  php artisan solo
else
  echo "[-] Solo not available; skipping dashboard."
fi
EOF
    chmod +x start.sh
    record_path "start.sh"
fi

# --- Track common artifact paths for cleanup ---
if [[ -d vendor ]]; then record_path "vendor"; fi
if [[ -d node_modules ]]; then record_path "node_modules"; fi
if [[ -f composer.lock ]]; then record_path "composer.lock"; fi
if [[ -f package-lock.json ]]; then record_path "package-lock.json"; fi
if [[ -f pnpm-lock.yaml ]]; then record_path "pnpm-lock.yaml"; fi
if [[ -f yarn.lock ]]; then record_path "yarn.lock"; fi
if [[ -f bun.lockb ]]; then record_path "bun.lockb"; fi
if [[ -d frontend ]]; then record_path "frontend"; fi

echo -e "\n${GREEN}EMPIRE SHIPPED.${NC}"
echo -e "Run ${CYAN}./start.sh${NC} to enter the cockpit."
echo -e "${GREEN}[✓] Forge complete.${NC}"
