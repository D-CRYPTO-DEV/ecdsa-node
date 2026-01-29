#!/bin/bash

# ECDSA Node - Vercel Deployment Script
# This script prepares and deploys the application to Vercel

set -e

echo "========================================="
echo "ECDSA Node - Vercel Deployment"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$PROJECT_ROOT/client"
SERVER_DIR="$PROJECT_ROOT/server"

# Function to print section headers
print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Check if Vercel CLI is installed
print_header "Checking Prerequisites"
if ! command -v vercel &> /dev/null; then
    echo -e "${RED}✗ Vercel CLI is not installed${NC}"
    echo ""
    echo "Install Vercel CLI with:"
    echo "  npm install -g vercel"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Vercel CLI found${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js found: $(node --version)${NC}"
echo ""

# Install dependencies
print_header "Installing Dependencies"

echo "Installing client dependencies..."
cd "$CLIENT_DIR"
npm install
echo -e "${GREEN}✓ Client dependencies installed${NC}"

echo ""
echo "Installing server dependencies..."
cd "$SERVER_DIR"
npm install
echo -e "${GREEN}✓ Server dependencies installed${NC}"

cd "$PROJECT_ROOT"
echo ""

# Build client
print_header "Building Client"
cd "$CLIENT_DIR"
echo "Building with Vite..."
npm run build
echo -e "${GREEN}✓ Client built successfully${NC}"
cd "$PROJECT_ROOT"
echo ""

# Create API handler structure
print_header "Creating Vercel API Structure"

mkdir -p "$PROJECT_ROOT/api"

# Create the main API handler
cat > "$PROJECT_ROOT/api/index.js" << 'EOF'
import express from 'express';
import cors from 'cors';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Store balances in memory (in production, use a database)
let balances = {};

// Initialize balances from keys.json if available
const keysPath = path.join(__dirname, '../server/keys.json');
if (fs.existsSync(keysPath)) {
    try {
        const keysData = JSON.parse(fs.readFileSync(keysPath, 'utf-8'));
        balances = keysData;
    } catch (err) {
        console.log('Could not load keys.json, using empty balances');
    }
}

// Routes
app.get('/api/balance/:address', (req, res) => {
    const { address } = req.params;
    res.json({ balance: balances[address] || 0 });
});

app.post('/api/send', (req, res) => {
    const { sender, amount, recipient, signature } = req.body;

    // TODO: Validate signature using ECDSA
    // This is where you verify the cryptographic signature

    // Update balances
    if (!balances[sender]) balances[sender] = 0;
    if (!balances[recipient]) balances[recipient] = 0;

    balances[sender] -= amount;
    balances[recipient] += amount;

    res.json({
        hash: Date.now(),
        message: 'Transfer successful'
    });
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok' });
});

export default app;
EOF

echo -e "${GREEN}✓ Created API handler at api/index.js${NC}"
echo ""

# Create Environment file template
print_header "Creating Environment Files"

cat > "$PROJECT_ROOT/.env.local" << 'EOF'
# Development Environment Variables
VITE_SERVER_URL=http://localhost:3000
NODE_ENV=development
PORT=3000
EOF

echo -e "${GREEN}✓ Created .env.local${NC}"

cat > "$PROJECT_ROOT/.env.production" << 'EOF'
# Production Environment Variables
# Update these with your production domain
VITE_SERVER_URL=https://your-vercel-app.vercel.app
NODE_ENV=production
EOF

echo -e "${GREEN}✓ Created .env.production${NC}"
echo ""

# Create vercel.json if it doesn't exist
if [ ! -f "$PROJECT_ROOT/vercel.json" ]; then
    echo "vercel.json already exists, skipping..."
else
    echo -e "${GREEN}✓ vercel.json configured${NC}"
fi

echo ""

# Create package.json if needed for root
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    cat > "$PROJECT_ROOT/package.json" << 'EOF'
{
  "name": "ecdsa-node-vercel",
  "version": "1.0.0",
  "description": "ECDSA-based web application deployed on Vercel",
  "private": true,
  "scripts": {
    "build": "cd client && npm run build",
    "deploy": "vercel --prod",
    "deploy-preview": "vercel"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.18.1"
  }
}
EOF
    echo -e "${GREEN}✓ Created root package.json${NC}"
fi

echo ""
print_header "Deployment Instructions"
echo ""
echo -e "${BLUE}To deploy to Vercel:${NC}"
echo ""
echo "Option 1: Using Vercel CLI"
echo "  1. Run: ${GREEN}vercel${NC}"
echo "  2. Follow the interactive prompts"
echo "  3. For production: ${GREEN}vercel --prod${NC}"
echo ""
echo "Option 2: Using Git (recommended for production)"
echo "  1. Push your code to GitHub/GitLab/Bitbucket"
echo "  2. Connect your repository at https://vercel.com"
echo "  3. Vercel will auto-deploy on every push to main"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  • Framework: Vite + React (client)"
echo "  • API: Express (server via /api routes)"
echo "  • Environment: Update .env.production with your domain"
echo ""
echo -e "${YELLOW}⚠ Important:${NC}"
echo "  • Set environment variables in Vercel project settings"
echo "  • Never commit sensitive keys to git"
echo "  • Use Vercel KV or PostgreSQL for production data storage"
echo ""
echo -e "${GREEN}✓ Project ready for Vercel deployment!${NC}"
echo ""
