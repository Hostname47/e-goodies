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
# 1. Install Git
# ============================================
print_info "Step 1: Installing Git..."

if command_exists git; then
    print_success "Git is already installed ($(git --version))"
else
    sudo apt update
    sudo apt install -y git
    if command_exists git; then
        print_success "Git installed successfully ($(git --version))"
    else
        print_error "Git installation failed"
        exit 1
    fi
fi

echo ""

# ============================================
# 2. Install NVM and Node.js
# ============================================
print_info "Step 2: Installing NVM and Node.js..."

# Check if NVM is already installed
if [ -d "$HOME/.nvm" ]; then
    print_success "NVM is already installed"
else
    print_warning "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    print_success "NVM installed"
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install and use latest LTS Node.js
if command_exists node; then
    print_success "Node.js is already installed ($(node --version))"
else
    print_warning "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    print_success "Node.js installed ($(node --version))"
fi

# Verify npm
if command_exists npm; then
    print_success "npm is available ($(npm --version))"
else
    print_error "npm not found"
    exit 1
fi

echo ""

# ============================================
# 3. Install Docker
# ============================================
print_info "Step 3: Setting up Docker..."

if command_exists docker; then
    print_success "Docker is already installed ($(docker --version))"
else
    print_warning "Installing Docker..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Update package index
    sudo apt-get update
    
    # Install dependencies
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Set up repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    print_success "Docker installed successfully"
fi

# Configure Docker permissions
print_info "Configuring Docker permissions..."
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker
print_success "Docker configured"

echo ""

# ============================================
# 4. Build React Frontend
# ============================================
print_info "Step 4: Building React frontend..."

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

cd software/backend/symfony-api

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found in software/backend/symfony-api"
    exit 1
fi

print_info "Starting Docker containers..."
docker compose -p e-goodies-api up -d

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

# Run database migrations (if applicable)
if docker compose exec php php bin/console list | grep -q "doctrine:migrations:migrate"; then
    print_info "Running database migrations..."
    docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction || print_warning "Migrations failed or not needed"
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
docker compose -p e-goodies-api ps
echo ""
print_info "Access your application:"
echo "  📱 Frontend: Run 'cd software/frontend && npm run dev'"
echo "  🔧 Backend API: http://localhost:8080"
echo "  🗄️  PHPMyAdmin: http://localhost:9002"
echo ""
print_warning "Important: Please log out and back in (or restart terminal) for Docker group changes to take effect"
echo "=========================================="
echo ""
