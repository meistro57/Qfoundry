#!/bin/bash

# --- The Imperial Palette ---
set -e
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

draw_header() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}           QFOUNDRY: THE FORGE MASTER v1.2       ${NC}"
    echo -e "${CYAN}==================================================${NC}"
}

# --- Stage 0: Privilege Check ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${YELLOW}[!] Escalating for system-level tempering...${NC}"
   sudo -v
fi

# --- Stage 1: Zero-State Environment ---
draw_header
echo -e "${BLUE}[1/8] Tempering PHP 8.4 & System Deps...${NC}"

sudo apt-get update -y && sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y

# Fix: Removed pcntl (it's built-in)
sudo apt-get install -y php8.4 php8.4-cli php8.4-common php8.4-curl \
                        php8.4-mbstring php8.4-xml php8.4-bcmath \
                        php8.4-sqlite3 php8.4-zip php8.4-intl \
                        php8.4-readline python3-venv libffi-dev \
                        libsodium-dev unzip git curl

# Install Bun
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Install Composer
if ! command -v composer &> /dev/null; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
fi

# --- Stage 2: Skeleton Construction ---
echo -e "${BLUE}[2/8] Creating Type-Safe Skeleton...${NC}"
rm -rf qfoundry_tmp
composer create-project nunomaduro/laravel-starter-kit qfoundry_tmp --prefer-dist --quiet
cp -r --update=none qfoundry_tmp/{*,.*} . || true
rm -rf qfoundry_tmp

# --- Stage 3: The 18-Skill Infusion (Iterative Recovery) ---
echo -e "\n${BLUE}[3/8] Executing Iterative Dependency Infusion...${NC}"

# Define our "God-Tier" package list
PACKAGES=(
    "prism-php/prism:^0.99"
    "moe-mizrak/laravel-openrouter:^2.0"
    "hosseinhezami/laravel-gemini:^1.0"
    "neuron-core/neuron-laravel:^0.3"
    "b7s/fluentvox:^1.0"
    "soloterm/solo:^0.5"
    "whispphp/whisp:^2.0"
    "chimit/prompt:^1.0"
    "mischasigtermans/laravel-toon:^1.0"
)

DEV_PACKAGES=(
    "rector/rector:^2.0"
    "web-id/laravel-playwright:^1.0"
    "tyghaykal/laravel-seed-generator:^2.2"
    "mrmarchone/laravel-auto-crud:^1.0"
)

# Function to install with grace
install_pkg() {
    echo -e "${YELLOW}[*] Infusing $1...${NC}"
    # We use --ignore-platform-reqs to bypass extension checks during the forge
    if ! composer require "$1" -W --ignore-platform-reqs --quiet; then
        echo -e "${RED}[!] Conflict detected for $1. Skipping for manual override...${NC}"
    else
        echo -e "${GREEN}[+] $1 Integrated.${NC}"
    fi
}

for pkg in "${PACKAGES[@]}"; do install_pkg "$pkg"; done
for pkg in "${DEV_PACKAGES[@]}"; do install_pkg "$pkg --dev"; done
# --- Stage 4: Directory Architecture ---
mkdir -p app/Foundry/{Agents,Cognition,Skills} resources/prompts bin

# --- Stage 5: Voice Logic Initialization ---
echo -e "${BLUE}[4/8] Building Python Neural Voice Environment...${NC}"
python3 -m venv venv
./venv/bin/pip install --upgrade pip --quiet
./vendor/bin/fluentvox install --pytorch --quiet

# --- Stage 6: The Overseer (Sentient PHP Injection) ---
echo -e "${BLUE}[5/8] Birthing the Overseer Agent...${NC}"

cat <<'EOF' > app/Foundry/Agents/Overseer.php
<?php

namespace App\Foundry\Agents;

use Prism\Prism;
use B7s\FluentVox\FluentVox;
use Mischasigtermans\LaravelToon\Facades\Toon;

class Overseer
{
    public function command(string $prompt): string
    {
        $response = Prism::text()
            ->using('google', 'gemini-1.5-pro')
            ->prompt($prompt)
            ->generate();

        Toon::compress($response->text);

        FluentVox::make()
            ->text($response->text)
            ->expressive()
            ->generate();

        return $response->text;
    }
}
EOF

# --- Stage 7: The SSH Gateway (Whisp) ---
echo -e "${BLUE}[6/8] Forging the SSH Entry Point...${NC}"

cat <<'EOF' > bin/overseer-ssh
<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';

use App\Foundry\Agents\Overseer;
use function Laravel\Prompts\text;
use function Laravel\Prompts\info;
use function Laravel\Prompts\spin;

$overseer = new Overseer();
info('--- QFOUNDRY OVERSEER ---');
$input = text('Architect Command:');
$response = spin(fn() => $overseer->command($input), 'Reasoning...');
info("\nResponse:");
echo $response . PHP_EOL;
EOF
chmod +x bin/overseer-ssh

# --- Stage 8: Ignition Script ---
cat <<'EOF' > start.sh
#!/bin/bash
echo "Igniting Qfoundry SSH & Dashboard..."
php -r "require 'vendor/autoload.php'; (new Whisp\Server(port: 2222))->run('bin/overseer-ssh');" &
php artisan solo
EOF
chmod +x start.sh

draw_header
echo -e "${GREEN}EMPIRE FULLY SHIPPED.${NC}"
echo -e "Next: ./start.sh"
