@echo off
REM ECDSA Node - Vercel Deployment Script for Windows

setlocal enabledelayedexpansion

echo.
echo =========================================
echo ECDSA Node - Vercel Deployment
echo =========================================
echo.

set "PROJECT_ROOT=%~dp0"
set "CLIENT_DIR=%PROJECT_ROOT%client"
set "SERVER_DIR=%PROJECT_ROOT%server"

REM Check if Vercel CLI is installed
echo Checking Prerequisites...
where vercel >nul 2>&1
if errorlevel 1 (
    echo ERROR: Vercel CLI is not installed
    echo.
    echo Install Vercel CLI with:
    echo   npm install -g vercel
    echo.
    exit /b 1
)

echo [SUCCESS] Vercel CLI found
where node >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js is not installed
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo [SUCCESS] Node.js found: %NODE_VERSION%
echo.

REM Install dependencies
echo =========================================
echo Installing Dependencies
echo =========================================
echo.

echo Installing client dependencies...
cd /d "%CLIENT_DIR%"
call npm install
if errorlevel 1 (
    echo Error: Failed to install client dependencies
    exit /b 1
)
echo [SUCCESS] Client dependencies installed
echo.

echo Installing server dependencies...
cd /d "%SERVER_DIR%"
call npm install
if errorlevel 1 (
    echo Error: Failed to install server dependencies
    exit /b 1
)
echo [SUCCESS] Server dependencies installed
cd /d "%PROJECT_ROOT%"
echo.

REM Build client
echo =========================================
echo Building Client
echo =========================================
echo.
cd /d "%CLIENT_DIR%"
echo Building with Vite...
call npm run build
if errorlevel 1 (
    echo Error: Failed to build client
    exit /b 1
)
echo [SUCCESS] Client built successfully
cd /d "%PROJECT_ROOT%"
echo.

REM Create API handler structure
echo =========================================
echo Creating Vercel API Structure
echo =========================================
echo.

if not exist "%PROJECT_ROOT%api" mkdir "%PROJECT_ROOT%api"

(
    echo import express from 'express';
    echo import cors from 'cors';
    echo import fs from 'fs';
    echo import path from 'path';
    echo import { fileURLToPath } from 'url';
    echo.
    echo const __filename = fileURLToPath(import.meta.url);
    echo const __dirname = path.dirname(__filename);
    echo.
    echo const app = express();
    echo.
    echo // Middleware
    echo app.use(cors());
    echo app.use(express.json());
    echo.
    echo // Store balances in memory
    echo let balances = {};
    echo.
    echo // Initialize balances from keys.json if available
    echo const keysPath = path.join(__dirname, '../server/keys.json');
    echo if (fs.existsSync(keysPath)) {
    echo     try {
    echo         const keysData = JSON.parse(fs.readFileSync(keysPath, 'utf-8'));
    echo         balances = keysData;
    echo     } catch (err) {
    echo         console.log('Could not load keys.json, using empty balances');
    echo     }
    echo }
    echo.
    echo // Routes
    echo app.get('/api/balance/:address', (req, res) =^> {
    echo     const { address } = req.params;
    echo     res.json({ balance: balances[address] ^|^| 0 });
    echo });
    echo.
    echo app.post('/api/send', (req, res) =^> {
    echo     const { sender, amount, recipient, signature } = req.body;
    echo.
    echo     // TODO: Validate signature using ECDSA
    echo     if (!balances[sender]) balances[sender] = 0;
    echo     if (!balances[recipient]) balances[recipient] = 0;
    echo.
    echo     balances[sender] -= amount;
    echo     balances[recipient] += amount;
    echo.
    echo     res.json({
    echo         hash: Date.now(),
    echo         message: 'Transfer successful'
    echo     });
    echo });
    echo.
    echo app.get('/api/health', (req, res) =^> {
    echo     res.json({ status: 'ok' });
    echo });
    echo.
    echo export default app;
) > "%PROJECT_ROOT%api\index.js"

echo [SUCCESS] Created API handler at api/index.js
echo.

REM Create Environment files
echo =========================================
echo Creating Environment Files
echo =========================================
echo.

(
    echo # Development Environment Variables
    echo VITE_SERVER_URL=http://localhost:3000
    echo NODE_ENV=development
    echo PORT=3000
) > "%PROJECT_ROOT%.env.local"

echo [SUCCESS] Created .env.local
echo.

(
    echo # Production Environment Variables
    echo VITE_SERVER_URL=https://your-vercel-app.vercel.app
    echo NODE_ENV=production
) > "%PROJECT_ROOT%.env.production"

echo [SUCCESS] Created .env.production
echo.

REM Create root package.json if it doesn't exist
if not exist "%PROJECT_ROOT%package.json" (
    (
        echo {
        echo   "name": "ecdsa-node-vercel",
        echo   "version": "1.0.0",
        echo   "description": "ECDSA-based web application deployed on Vercel",
        echo   "private": true,
        echo   "scripts": {
        echo     "build": "cd client ^&^& npm run build",
        echo     "deploy": "vercel --prod",
        echo     "deploy-preview": "vercel"
        echo   },
        echo   "dependencies": {
        echo     "cors": "^2.8.5",
        echo     "express": "^4.18.1"
        echo   }
        echo }
    ) > "%PROJECT_ROOT%package.json"
    echo [SUCCESS] Created root package.json
)

echo.
echo =========================================
echo Deployment Instructions
echo =========================================
echo.
echo To deploy to Vercel:
echo.
echo Option 1: Using Vercel CLI
echo   1. Run: vercel
echo   2. Follow the interactive prompts
echo   3. For production: vercel --prod
echo.
echo Option 2: Using Git (recommended for production)
echo   1. Push your code to GitHub/GitLab/Bitbucket
echo   2. Connect your repository at https://vercel.com
echo   3. Vercel will auto-deploy on every push to main
echo.
echo Configuration:
echo   - Framework: Vite + React (client)
echo   - API: Express (server via /api routes)
echo   - Environment: Update .env.production with your domain
echo.
echo IMPORTANT:
echo   - Set environment variables in Vercel project settings
echo   - Never commit sensitive keys to git
echo   - Use Vercel KV or PostgreSQL for production data storage
echo.
echo [SUCCESS] Project ready for Vercel deployment!
echo.

endlocal
