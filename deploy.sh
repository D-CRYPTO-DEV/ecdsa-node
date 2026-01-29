#!/bin/bash

# ECDSA Node Deployment Script
# This script automates the deployment of both client and server

set -e  # Exit on error

echo "========================================="
echo "ECDSA Node Deployment Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$PROJECT_ROOT/client"
SERVER_DIR="$PROJECT_ROOT/server"
DEPLOY_DIR="${DEPLOY_DIR:-./dist}"

echo -e "${BLUE}Project Root: $PROJECT_ROOT${NC}"
echo ""

# Function to print section headers
print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Function to check if directory exists
check_dir() {
    if [ ! -d "$1" ]; then
        echo -e "${YELLOW}Warning: Directory $1 not found${NC}"
        return 1
    fi
    return 0
}

# Install client dependencies
print_header "Installing Client Dependencies"
if check_dir "$CLIENT_DIR"; then
    cd "$CLIENT_DIR"
    echo "Running npm install..."
    npm install
    echo -e "${GREEN}✓ Client dependencies installed${NC}"
    cd "$PROJECT_ROOT"
else
    exit 1
fi

echo ""

# Build client
print_header "Building Client"
if check_dir "$CLIENT_DIR"; then
    cd "$CLIENT_DIR"
    echo "Building with Vite..."
    npm run build
    echo -e "${GREEN}✓ Client build complete${NC}"
    cd "$PROJECT_ROOT"
else
    exit 1
fi

echo ""

# Install server dependencies
print_header "Installing Server Dependencies"
if check_dir "$SERVER_DIR"; then
    cd "$SERVER_DIR"
    echo "Running npm install..."
    npm install
    echo -e "${GREEN}✓ Server dependencies installed${NC}"
    cd "$PROJECT_ROOT"
else
    exit 1
fi

echo ""

# Create deployment package structure
print_header "Creating Deployment Package"

# Create deploy directory if it doesn't exist
if [ ! -d "$DEPLOY_DIR" ]; then
    mkdir -p "$DEPLOY_DIR"
    echo "Created deployment directory: $DEPLOY_DIR"
fi

# Copy built client to deploy directory
if [ -d "$CLIENT_DIR/dist" ]; then
    cp -r "$CLIENT_DIR/dist" "$DEPLOY_DIR/public"
    echo -e "${GREEN}✓ Client build copied to $DEPLOY_DIR/public${NC}"
else
    echo -e "${YELLOW}Warning: Client dist directory not found${NC}"
fi

# Copy server files
if check_dir "$SERVER_DIR"; then
    mkdir -p "$DEPLOY_DIR/server"
    cp "$SERVER_DIR/index.js" "$DEPLOY_DIR/server/"
    cp "$SERVER_DIR/package.json" "$DEPLOY_DIR/server/"
    cp "$SERVER_DIR/package-lock.json" "$DEPLOY_DIR/server/" 2>/dev/null || true
    
    # Copy middleware if it exists
    if [ -d "$SERVER_DIR/middleware" ]; then
        cp -r "$SERVER_DIR/middleware" "$DEPLOY_DIR/server/"
    fi
    
    # Copy keys if it exists
    if [ -f "$SERVER_DIR/keys.json" ]; then
        cp "$SERVER_DIR/keys.json" "$DEPLOY_DIR/server/"
        echo -e "${YELLOW}⚠ Note: keys.json included in deployment${NC}"
    fi
    
    echo -e "${GREEN}✓ Server files copied to $DEPLOY_DIR/server${NC}"
else
    exit 1
fi

echo ""

# Create .env file template if it doesn't exist
print_header "Environment Configuration"
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    cat > "$DEPLOY_DIR/.env" << 'EOF'
# Server Configuration
PORT=3042
NODE_ENV=production

# Client Configuration
VITE_SERVER_URL=http://localhost:3042
EOF
    echo -e "${GREEN}✓ Created .env template at $DEPLOY_DIR/.env${NC}"
    echo -e "${YELLOW}⚠ Please update the .env file with your production settings${NC}"
fi

echo ""

# Create startup script
print_header "Creating Startup Scripts"

# Create start script for Unix-like systems
cat > "$DEPLOY_DIR/start.sh" << 'EOF'
#!/bin/bash
echo "Starting ECDSA Node Application..."
cd "$(dirname "$0")"
source .env

echo "Starting server on port $PORT..."
cd server
node index.js
EOF

chmod +x "$DEPLOY_DIR/start.sh"
echo -e "${GREEN}✓ Created start.sh${NC}"

# Create start script for Windows
cat > "$DEPLOY_DIR/start.bat" << 'EOF'
@echo off
echo Starting ECDSA Node Application...
cd /d "%~dp0"
for /f "tokens=*" %%i in (.env) do set %%i

echo Starting server on port %PORT%...
cd server
node index.js
EOF

echo -e "${GREEN}✓ Created start.bat${NC}"

echo ""

# Create README for deployment
print_header "Creating Deployment Documentation"

cat > "$DEPLOY_DIR/DEPLOYMENT.md" << 'EOF'
# ECDSA Node - Deployment Guide

## Prerequisites
- Node.js v14 or higher
- npm

## Deployment Structure

```
dist/
├── public/                 # Built client (React app)
├── server/                 # Backend server
│   ├── index.js
│   ├── package.json
│   ├── middleware/
│   └── keys.json
├── .env                    # Environment variables
├── start.sh               # Start script (Unix/Linux/Mac)
├── start.bat              # Start script (Windows)
└── DEPLOYMENT.md          # This file
```

## Configuration

1. **Update .env file:**
   ```
   PORT=3042
   NODE_ENV=production
   VITE_SERVER_URL=http://localhost:3042
   ```

2. **Update server configuration:**
   - Edit `server/keys.json` if needed
   - Update any environment-specific settings

## Starting the Application

### Linux/Mac
```bash
chmod +x start.sh
./start.sh
```

### Windows
```bash
start.bat
```

### Manual Start
```bash
cd server
npm install
PORT=3042 node index.js
```

## Client Access

Once the server is running, access the client at:
- Client served from: `http://localhost:3042/`
- Default port can be changed in `.env`

## Production Deployment

For production deployment:

1. **Environment Variables:**
   - Set `NODE_ENV=production`
   - Configure proper `VITE_SERVER_URL` pointing to your production server

2. **Security:**
   - Never commit `keys.json` with private keys
   - Use environment variables for sensitive configuration
   - Enable HTTPS on production

3. **Server:**
   - Use a process manager like `pm2` or `forever`
   - Monitor application logs
   - Set up automated backups

### Example PM2 Setup
```bash
npm install -g pm2
pm2 start server/index.js --name "ecdsa-node"
pm2 save
pm2 startup
```

## Troubleshooting

- **Port already in use:** Change the PORT in .env
- **Module not found:** Ensure npm install was run
- **Client not loading:** Check VITE_SERVER_URL configuration

## Support

For issues, check the main README.md in the project root.
EOF

echo -e "${GREEN}✓ Created DEPLOYMENT.md${NC}"

echo ""
print_header "Deployment Complete!"
echo ""
echo -e "${GREEN}✓ All components built and packaged successfully!${NC}"
echo ""
echo -e "${BLUE}Deployment package location: $DEPLOY_DIR${NC}"
echo ""
echo "Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Run ./start.sh (Unix/Linux/Mac) or start.bat (Windows)"
echo "3. Access the app at http://localhost:3042"
echo ""
echo "For more information, see: $DEPLOY_DIR/DEPLOYMENT.md"
echo ""
