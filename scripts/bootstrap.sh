#!/bin/bash
# Localfarm Client Bootstrap Script
# One-liner to set up client configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Localfarm Client Bootstrap${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Detect platform
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM=Windows;;
    *)          PLATFORM="UNKNOWN:${OS}"
esac

echo -e "${GREEN}✓${NC} Platform detected: ${PLATFORM}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗${NC} Don't run this script as root!"
    echo "  Run as normal user - it will ask for sudo when needed."
    exit 1
fi

# Check for Ansible
if ! command -v ansible-pull &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Ansible not found. Installing..."

    case "${PLATFORM}" in
        Mac)
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}✗${NC} Homebrew required. Install from: https://brew.sh"
                exit 1
            fi
            brew install ansible
            ;;
        Linux)
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y ansible
            elif command -v yum &> /dev/null; then
                sudo yum install -y ansible
            else
                echo -e "${YELLOW}⚠${NC} Falling back to pip..."
                pip3 install --user ansible
            fi
            ;;
        *)
            echo -e "${RED}✗${NC} Unsupported platform for automatic installation"
            echo "  Please install Ansible manually: https://docs.ansible.com/ansible/latest/installation_guide/"
            exit 1
            ;;
    esac
fi

echo -e "${GREEN}✓${NC} Ansible: $(ansible --version | head -1)"

# Determine Git repo URL
DEFAULT_REPO="https://github.com/thusby/localfarm-client-config.git"
REPO="${LOCALFARM_REPO:-$DEFAULT_REPO}"

echo
echo -e "${BLUE}Repository:${NC} ${REPO}"
echo

# Confirm
echo -e "${YELLOW}This will:${NC}"
echo "  1. Clone configuration from Git"
echo "  2. Update /etc/hosts with Localfarm services"
echo "  3. Set up automatic updates (hourly)"
echo

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Run ansible-pull
echo
echo -e "${BLUE}Running ansible-pull...${NC}"
echo

sudo ansible-pull \
    -U "${REPO}" \
    -i localhost, \
    playbooks/bootstrap.yml \
    -v

echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Bootstrap Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "Next steps:"
echo "  • Check /etc/hosts for Localfarm services"
echo "  • Ansible-pull will run automatically every hour"
echo "  • View logs: tail -f /var/log/ansible-pull.log"
echo "  • Manual update: sudo /usr/local/bin/localfarm-ansible-pull"
echo
