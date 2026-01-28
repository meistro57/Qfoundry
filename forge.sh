#!/bin/bash
set -e

# --- Colors ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- Initial State ---
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
    
    echo -e "\n${PURPLE}Current Selection: Tailor your empire before ignition.${NC}"
    echo -e "${CYAN}==================================================${NC}"
}

# --- Interactive Cockpit ---
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

echo -e "\n${GREEN}[*] Ignition confirmed. Forging the Empire...${NC}"
[[ $EUID -ne 0 ]] && sudo -v

# --- Stage 1: System & Skeleton ---
echo -e "${BLUE}[1/5] Tempering PHP 8.4 & Skeleton...${NC}"
sudo apt-get update -y && sudo apt-get install -y php8.4 php8.4-cli php8.4-{curl,mbstring,xml,bcmath,sqlite3,zip,intl,pcntl} python3-venv libffi-dev libsodium-dev unzip git curl --quiet

rm -rf qfoundry_tmp
composer create-project nunomaduro/laravel-starter-kit qfoundry_tmp --prefer-dist --quiet
cp -r --update=none qfoundry_tmp/{*,.*} . || true
rm -rf qfoundry_tmp

# --- Stage 2: The Infusion ---
install_pkg() {
    local pkg=$1
    local is_dev=$2
    if [[ "$is_dev" == "true" ]]; then
        composer require "$pkg" --dev -W --ignore-platform-reqs --quiet
    else
        composer require "$pkg" -W --ignore-platform-reqs --quiet
    fi
}

[[ $INSTALL_BRAIN == true ]] && (echo -e "${BLUE}[+] Infusing Neural Core...${NC}"; install_pkg "prism-php/prism:^0.99" "false"; install_pkg "neuron-core/neuron-laravel:^0.3" "false")
[[ $INSTALL_VOICE == true ]] && (echo -e "${PURPLE}[+] Infusing Vocal Cords...${NC}"; install_pkg "b7s/fluentvox:^1.0" "false"; python3 -m venv venv; ./venv/bin/pip install --upgrade pip --quiet; ./vendor/bin/fluentvox install --pytorch --quiet)
[[ $INSTALL_TUI == true ]] && (echo -e "${YELLOW}[+] Forging the Cockpit...${NC}"; install_pkg "soloterm/solo:^0.5" "false"; install_pkg "whispphp/whisp:^2.0" "false"; php artisan solo:install --quiet)
[[ $INSTALL_GUARD == true ]] && (echo -e "${CYAN}[+] Activating The Guard...${NC}"; install_pkg "rector/rector:^2.0" "true"; install_pkg "web-id/laravel-playwright:^1.0" "true")

# --- Stage 3: Sentience Injection ---
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

# --- Stage 4: Ignition ---
cat <<'EOF' > start.sh
#!/bin/bash
echo "Igniting Qfoundry SSH & Dashboard..."
php -r "require 'vendor/autoload.php'; (new Whisp\Server(port: 2222))->run('bin/overseer-ssh');" &
php artisan solo
EOF
chmod +x start.sh

echo -e "\n${GREEN}EMPIRE SHIPPED.${NC}"
echo -e "Run ${CYAN}./start.sh${NC} to enter the cockpit."
