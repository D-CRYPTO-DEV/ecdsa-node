@echo off
REM ECDSA Node Deployment Script for Windows
REM This script automates the deployment of both client and server

setlocal enabledelayedexpansion

echo.
echo =========================================
echo ECDSA Node Deployment Script
echo =========================================
echo.

REM Get the project root directory
set "PROJECT_ROOT=%~dp0"
set "CLIENT_DIR=%PROJECT_ROOT%client"
set "SERVER_DIR=%PROJECT_ROOT%server"
set "DEPLOY_DIR=%PROJECT_ROOT%dist"

echo Project Root: %PROJECT_ROOT%
echo.

REM Check if directories exist
if not exist "%CLIENT_DIR%" (
    echo Warning: Client directory not found at %CLIENT_DIR%
    exit /b 1
)

if not exist "%SERVER_DIR%" (
    echo Warning: Server directory not found at %SERVER_DIR%
    exit /b 1
)

REM Install client dependencies
echo.
echo =========================================
echo Installing Client Dependencies
echo =========================================
cd /d "%CLIENT_DIR%"
echo Running npm install...
call npm install
if errorlevel 1 (
    echo Error: Failed to install client dependencies
    exit /b 1
)
echo [SUCCESS] Client dependencies installed
echo.

REM Build client
echo =========================================
echo Building Client
echo =========================================
cd /d "%CLIENT_DIR%"
echo Building with Vite...
call npm run build
if errorlevel 1 (
    echo Error: Failed to build client
    exit /b 1
)
echo [SUCCESS] Client build complete
echo.

REM Install server dependencies
echo =========================================
echo Installing Server Dependencies
echo =========================================
cd /d "%SERVER_DIR%"
echo Running npm install...
call npm install
if errorlevel 1 (
    echo Error: Failed to install server dependencies
    exit /b 1
)
echo [SUCCESS] Server dependencies installed
echo.

REM Create deployment package structure
echo =========================================
echo Creating Deployment Package
echo =========================================

REM Create deploy directory if it doesn't exist
if not exist "%DEPLOY_DIR%" (
    mkdir "%DEPLOY_DIR%"
    echo Created deployment directory: %DEPLOY_DIR%
)

REM Copy built client to deploy directory
if exist "%CLIENT_DIR%\dist" (
    if exist "%DEPLOY_DIR%\public" rmdir /s /q "%DEPLOY_DIR%\public"
    xcopy "%CLIENT_DIR%\dist" "%DEPLOY_DIR%\public" /e /i /y
    echo [SUCCESS] Client build copied to %DEPLOY_DIR%\public
) else (
    echo Warning: Client dist directory not found
)

REM Copy server files
mkdir "%DEPLOY_DIR%\server" 2>nul
copy "%SERVER_DIR%\index.js" "%DEPLOY_DIR%\server\" /y
copy "%SERVER_DIR%\package.json" "%DEPLOY_DIR%\server\" /y
if exist "%SERVER_DIR%\package-lock.json" (
    copy "%SERVER_DIR%\package-lock.json" "%DEPLOY_DIR%\server\" /y
)

REM Copy middleware if it exists
if exist "%SERVER_DIR%\middleware" (
    xcopy "%SERVER_DIR%\middleware" "%DEPLOY_DIR%\server\middleware" /e /i /y
)

REM Copy keys if it exists
if exist "%SERVER_DIR%\keys.json" (
    copy "%SERVER_DIR%\keys.json" "%DEPLOY_DIR%\server\" /y
    echo WARNING: keys.json included in deployment
)

echo [SUCCESS] Server files copied to %DEPLOY_DIR%\server
echo.

REM Create .env file template if it doesn't exist
echo =========================================
echo Environment Configuration
echo =========================================
if not exist "%DEPLOY_DIR%\.env" (
    (
        echo # Server Configuration
        echo PORT=3042
        echo NODE_ENV=production
        echo.
        echo # Client Configuration
        echo VITE_SERVER_URL=http://localhost:3042
    ) > "%DEPLOY_DIR%\.env"
    echo [SUCCESS] Created .env template at %DEPLOY_DIR%\.env
    echo WARNING: Please update the .env file with your production settings
) else (
    echo .env file already exists
)
echo.

REM Create startup batch script
echo =========================================
echo Creating Startup Scripts
echo =========================================

(
    @echo off
    echo Starting ECDSA Node Application...
    cd /d "%%~dp0"
    setlocal enabledelayedexpansion
    for /f "tokens=*" %%%%i in (.env) do set %%%%i
    echo Starting server on port !PORT!...
    cd server
    node index.js
) > "%DEPLOY_DIR%\start.bat"
echo [SUCCESS] Created start.bat
echo.

REM Create README for deployment
echo =========================================
echo Creating Deployment Documentation
echo =========================================

(
    echo # ECDSA Node - Deployment Guide
    echo.
    echo ## Prerequisites
    echo - Node.js v14 or higher
    echo - npm
    echo.
    echo ## Deployment Structure
    echo.
    echo ```
    echo dist/
    echo ├── public/                 # Built client ^(React app^)
    echo ├── server/                 # Backend server
    echo │   ├── index.js
    echo │   ├── package.json
    echo │   ├── middleware/
    echo │   └── keys.json
    echo ├── .env                    # Environment variables
    echo ├── start.bat               # Start script ^(Windows^)
    echo └── DEPLOYMENT.md           # This file
    echo ```
    echo.
    echo ## Configuration
    echo.
    echo 1. **Update .env file:**
    echo    ```
    echo    PORT=3042
    echo    NODE_ENV=production
    echo    VITE_SERVER_URL=http://localhost:3042
    echo    ```
    echo.
    echo 2. **Update server configuration:**
    echo    - Edit `server/keys.json` if needed
    echo    - Update any environment-specific settings
    echo.
    echo ## Starting the Application
    echo.
    echo ### Windows
    echo ```bash
    echo start.bat
    echo ```
    echo.
    echo ### Manual Start
    echo ```bash
    echo cd server
    echo npm install
    echo set PORT=3042
    echo node index.js
    echo ```
    echo.
    echo ## Client Access
    echo.
    echo Once the server is running, access the client at:
    echo - Client served from: `http://localhost:3042/`
    echo - Default port can be changed in `.env`
    echo.
    echo ## Troubleshooting
    echo.
    echo - **Port already in use:** Change the PORT in .env
    echo - **Module not found:** Ensure npm install was run
    echo - **Client not loading:** Check VITE_SERVER_URL configuration
) > "%DEPLOY_DIR%\DEPLOYMENT.md"

echo [SUCCESS] Created DEPLOYMENT.md
echo.

echo =========================================
echo Deployment Complete!
echo =========================================
echo.
echo [SUCCESS] All components built and packaged successfully!
echo.
echo Deployment package location: %DEPLOY_DIR%
echo.
echo Next steps:
echo 1. Update .env file with your configuration
echo 2. Run start.bat
echo 3. Access the app at http://localhost:3042
echo.
echo For more information, see: %DEPLOY_DIR%\DEPLOYMENT.md
echo.

endlocal
