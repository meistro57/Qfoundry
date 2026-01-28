#!/bin/bash
set -e

# --- Colors ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

# --- State ---
INSTALL_BRAIN=true
INSTALL_VOICE=true
INSTALL_GUARD=true
INSTALL_TUI=true

draw_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}           QFOUNDRY: THE IMPERIAL FORGE          ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "Toggle components (1-4), 'S' to SHIP, 'Q' to Quit:\n"
    
    echo -ne "[ 1 ] " && [[ $INSTALL_BRAIN == true ]] && echo -e "${GREEN}[ON]${NC}  The Brain (Prism, Neuron, OpenRouter)" || echo -e "${RED}[OFF]${NC} The Brain"
    echo -ne "[ 2 ] " && [[ $INSTALL_VOICE == true ]] && echo -e "${GREEN}[ON]${NC}  The Voice (FluentVox + Python Venv)" || echo -e "${RED}[OFF]${NC} The Voice"
    echo -ne "[ 3 ] " && [[ $INSTALL_GUARD == true ]] && echo -e "${GREEN}[ON]${NC}  The Guard (Playwright, Rector, PHPStan)" || echo -e "${RED}[OFF]${NC} The Guard"
    echo -ne "[ 4 ] " && [[ $INSTALL_TUI == true ]] && echo -e "${GREEN}[ON]${NC}  The Cockpit (Solo, Whisp, Auto-CRUD)" || echo -e "${RED}[OFF]${NC} The Cockpit"
    
    echo -e "\n${PURPLE}Current Selection: All skills active by default.${NC}"
    echo -e "${CYAN}==================================================${NC}"
}

# --- Interaction Loop ---
while true; do
    draw_menu
    read -rsn1 opt
    case $opt in
        1) INSTALL_BRAIN=$([[ $INSTALL_BRAIN == true ]] && echo false || echo true) ;;
        2) INSTALL_VOICE=$([[ $INSTALL_VOICE == true ]] && echo false || echo true) ;;
        3) INSTALL_GUARD=$([[ $INSTALL_GUARD == true ]] && echo false || echo true) ;;
        4) INSTALL_TUI=$([[ $INSTALL_TUI == true ]] && echo false || echo true) ;;
        [Ss]) break ;;
        [Qq]) exit ;;
    esac
done

# --- Execution ---
echo -e "\n${GREEN}[*] Ignition confirmed. Preparing the Empire...${NC}"

# 1. System Check
[[ $EUID -ne 0 ]] && sudo -v

# 2. Base Skeleton
rm -rf qfoundry_tmp
composer create-project nunomaduro/laravel-starter-kit qfoundry_tmp --prefer-dist --quiet
cp -r --update=none qfoundry_tmp/{*,.*} . || true
rm -rf qfoundry_tmp

# 3. Dynamic Infusion
install_pkg() {
    local is_dev=$2
    if [[ "$is_dev" == "true" ]]; then
        composer require "$1" --dev -W --ignore-platform-reqs --quiet
    else
        composer require "$1" -W --ignore-platform-reqs --quiet
    fi
}

if [[ $INSTALL_BRAIN == true ]]; then
    echo -e "${BLUE}[+] Infusing Neural Core...${NC}"
    install_pkg "prism-php/prism:^0.99" false
    install_pkg "moe-mizrak/laravel-openrouter:^2.0" false
    install_pkg "neuron-core/neuron-laravel:^0.3" false
fi

if [[ $INSTALL_VOICE == true ]]; then
    echo -e "${PURPLE}[+] Infusing Vocal Cords...${NC}"
    install_pkg "b7s/fluentvox:^1.0" false
    python3 -m venv venv
    ./venv/bin/pip install --upgrade pip --quiet
    ./vendor/bin/fluentvox install --pytorch --quiet
fi

if [[ $INSTALL_TUI == true ]]; then
    echo -e "${YELLOW}[+] Forging the Cockpit...${NC}"
    install_pkg "soloterm/solo:^0.5" false
    install_pkg "whispphp/whisp:^2.0" false
    php artisan solo:install --quiet
fi

# 4. Final Sentiment (Stage 6-8)
mkdir -p app/Foundry/Agents bin
cat <<'EOF' > app/Foundry/Agents/Overseer.php
<?php
namespace App\Foundry\Agents;
use Prism\Prism;
class Overseer {
    public function command(\$prompt) {
        return Prism::text()->using('google', 'gemini-1.5-pro')->prompt(\$prompt)->generate()->text;
    }
}
EOF

# ... (Insert Whisp bin and start.sh logic here) ...

echo -e "\n${GREEN}EMPIRE SHIPPED.${NC}"
