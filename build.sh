#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Error handling
set -e
trap 'print_error "Script failed at line $LINENO"' ERR

echo ""
echo "=========================================="
echo "  🚀 E-Goodies Setup Script"
echo "=========================================="
echo ""

# ============================================
# 0. Pre-check: Required dependencies
# ============================================
print_info "Checking required tools..."

MISSING=()

for cmd in git node npm docker; do
    if command_exists "$cmd"; then
        print_success "$cmd is installed: $($cmd --version | head -n 1)"
    else
        print_error "$cmd is not installed!"
        MISSING+=("$cmd")
    fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
    echo ""
    print_error "Missing dependencies: ${MISSING[*]}"
    echo "Please install them before running this script."
    echo ""
    exit 1
fi

# ============================================
# 0.1 Ensure Docker socket permissions
# ============================================
if [ -S /var/run/docker.sock ]; then
    SOCKET_PERM=$(stat -c "%a" /var/run/docker.sock)
    if [ "$SOCKET_PERM" != "777" ]; then
        print_warning "Docker socket permissions are $SOCKET_PERM, changing to 777..."
        if [ "$EUID" -ne 0 ]; then
            sudo chmod 777 /var/run/docker.sock || {
                print_error "Failed to change Docker socket permissions. Please run script with sudo."
                exit 1
            }
        else
            chmod 777 /var/run/docker.sock
        fi
        print_success "Docker socket permissions set to 777"
    else
        print_success "Docker socket permissions already set to 777"
    fi
else
    print_error "Docker socket not found at /var/run/docker.sock"
    echo "Make sure Docker service is running before continuing."
    exit 1
fi

echo ""
print_success "All required tools and permissions are set."
echo ""

# ============================================
# 0.2 Ensure correct ownership for frontend
# ============================================
if [ -d "software/frontend" ]; then
    print_info "Checking ownership of software/frontend..."
    OWNER=$(stat -c "%U" software/frontend)
    if [ "$OWNER" != "$USER" ]; then
        print_warning "Frontend directory is owned by $OWNER, changing ownership to $USER..."
        if [ "$EUID" -ne 0 ]; then
            sudo chown -R "$USER":"$USER" software/frontend || {
                print_error "Failed to change ownership of software/frontend. Please run script with sudo."
                exit 1
            }
        else
            chown -R "$USER":"$USER" software/frontend
        fi
        print_success "Ownership of software/frontend set to $USER"
    else
        print_success "Ownership of software/frontend already set to $USER"
    fi

    # Fix common npm permission issues
    print_info "Adjusting permissions for npm operations..."
    chmod -R 755 software/frontend
    print_success "Permissions adjusted for software/frontend"

else
    print_warning "Frontend directory not found: software/frontend"
fi

echo ""

# ============================================
# 1. Build React frontend
# ============================================
print_info "Step 1: Building React frontend..."

if [ ! -d "software/frontend" ]; then
    print_error "Frontend directory not found: software/frontend"
    exit 1
fi

cd software/frontend

if [ ! -f "package.json" ]; then
    print_error "package.json not found in software/frontend"
    exit 1
fi

print_info "Installing frontend dependencies..."
npm install

print_info "Building React app..."
npm run build

if [ -d "dist" ] || [ -d "build" ]; then
    print_success "React app built successfully"
else
    print_warning "Build directory not found. Build might have failed."
fi

cd ../..

echo ""

# ============================================
# 5. Setup Symfony Backend
# ============================================
print_info "Step 5: Setting up Symfony backend..."

if [ ! -d "software/backend/symfony-api" ]; then
    print_error "Symfony directory not found: software/backend/symfony-api"
    exit 1
fi

# Check if compose.yaml exists
if [ ! -f "compose.yaml" ]; then
    print_error "compose.yml not found"
    exit 1
fi

print_info "Starting Docker containers..."
docker compose up -d

print_info "Waiting for containers to be ready..."
sleep 5

print_info "Installing Composer dependencies..."
docker compose exec php composer install --no-cache

# Copy environment file if it doesn't exist
if [ -f ".env.dev" ]; then
    if [ ! -f ".env.dev.local" ]; then
        print_info "Creating .env.dev.local..."
        docker compose exec php cp .env.dev .env.dev.local
        print_success "Environment file created"
    else
        print_warning ".env.dev.local already exists, skipping..."
    fi
else
    print_warning ".env.dev not found, skipping environment setup"
fi

cd ../../..

echo ""

# ============================================
# 6. Final Summary
# ============================================
echo "=========================================="
echo "  ✅ Setup Complete!"
echo "=========================================="
echo ""
print_success "Git: $(git --version)"
print_success "Node.js: $(node --version)"
print_success "npm: $(npm --version)"
print_success "Docker: $(docker --version)"
echo ""
print_info "Services Status:"
docker compose ps
echo ""
print_info "Access your application:"
echo "  ✅ 📱 Frontend: Run 'cd software/frontend && npm run dev'"
echo "  ✅ 🔧 Backend API: http://localhost:8080"
echo "  ✅ 🗄️  PHPMyAdmin: http://localhost:9002"
echo ""
print_warning "Important: Please log out and back in (or restart terminal) for Docker group changes to take effect"
echo "=========================================="
echo ""
