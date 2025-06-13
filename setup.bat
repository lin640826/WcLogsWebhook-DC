@echo off
setlocal EnableDelayedExpansion

echo Warcraft Logs Discord Webhook Setup > setup.log
echo %date% %time% >> setup.log
echo.

:: Set project directory
cd /d "D:\1WarcraftLOGSUPLOAD\WarcraftlogsDiscordWebhook-patch-2"
if %ERRORLEVEL% neq 0 (
    echo Failed to change to project directory. Please check the path. >> setup.log
    echo Failed to change to project directory. Please check the path.
    pause
    exit
)

:: Prompt for custom Node.js path
set /p NODE_PATH=Enter your Node.js installation path (e.g., D:\1WarcraftLOGSUPLOAD, or press Enter for default):
if not "!NODE_PATH!"=="" (
    set "PATH=%PATH%;!NODE_PATH!"
    echo Using custom Node.js path: !NODE_PATH! >> setup.log
    echo Using custom Node.js path: !NODE_PATH!
)

:: Check if Node.js is installed
node --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Node.js not found. Downloading and installing Node.js... >> setup.log
    echo Node.js not found. Downloading and installing Node.js...
    powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.16.0/node-v22.16.0-x64.msi' -OutFile 'node-installer.msi'"
    echo Installing Node.js... >> setup.log
    echo Installing Node.js...
    msiexec /i node-installer.msi /quiet
    del node-installer.msi
    echo Node.js installed. Please restart this script. >> setup.log
    echo Node.js installed. Please restart this script.
    pause
    exit
)

:: Check if dependencies are installed
if not exist node_modules (
    echo Installing dependencies... >> setup.log
    echo Installing dependencies...
    npm install
    if %ERRORLEVEL% neq 0 (
        echo Failed to install dependencies. Check npm logs. >> setup.log
        echo Failed to install dependencies. Check npm logs.
        pause
        exit
    )
) else (
    echo Dependencies already installed. >> setup.log
    echo Dependencies already installed.
)

:: Check if config.json exists
if exist config.json (
    set /p RECONFIGURE=Config file found. Reconfigure Warcraft Logs ID and API Key? (y/n):
    echo User input for reconfigure: !RECONFIGURE! >> setup.log
    if /i "!RECONFIGURE!"=="y" (
        echo Enter your Warcraft Logs details. >> setup.log
        echo Enter your Warcraft Logs details.
        set /p WCL_USER_ID=Enter your Warcraft Logs User ID:
        set /p WCL_API_KEY=Enter your Warcraft Logs API Key:
        echo Writing config.json with ID: !WCL_USER_ID! >> setup.log
        echo { > config.json
        echo   "wclUserId": "!WCL_USER_ID!", >> config.json
        echo   "wclApiKey": "!WCL_API_KEY!" >> config.json
        echo } >> config.json
        if %ERRORLEVEL% neq 0 (
            echo Failed to write config.json. Check permissions. >> setup.log
            echo Failed to write config.json. Check permissions.
            pause
            exit
        )
        echo Configuration updated. >> setup.log
        echo Configuration updated.
    ) else (
        echo Configuration already set in config.json. >> setup.log
        echo Configuration already set in config.json.
    )
) else (
    echo Config file not found. Please enter your Warcraft Logs details. >> setup.log
    echo Config file not found. Please enter your Warcraft Logs details.
    set /p WCL_USER_ID=Enter your Warcraft Logs User ID:
    set /p WCL_API_KEY=Enter your Warcraft Logs API Key:
    echo Writing config.json with ID: !WCL_USER_ID! >> setup.log
    echo { > config.json
    echo   "wclUserId": "!WCL_USER_ID!", >> config.json
    echo   "wclApiKey": "!WCL_API_KEY!" >> config.json
    echo } >> config.json
    if %ERRORLEVEL% neq 0 (
        echo Failed to write config.json. Check permissions. >> setup.log
        echo Failed to write config.json. Check permissions.
        pause
        exit
    )
    echo Configuration created. >> setup.log
    echo Configuration created.
)

:: Pause to check configuration
echo Configuration complete. Press any key to start the webhook... >> setup.log
echo Configuration complete. Press any key to start the webhook...
pause

:: Test run
echo Starting the webhook... >> setup.log
echo Starting the webhook...
node app.js
if %ERRORLEVEL% neq 0 (
    echo Failed to start webhook. Check package.json or app.js. >> setup.log
    echo Failed to start webhook. Check package.json or app.js.
    pause
    exit
)

echo. >> setup.log
echo To check if the webhook is running, use the following commands: >> setup.log
echo   cd D:\1WarcraftLOGSUPLOAD\WarcraftlogsDiscordWebhook-patch-2 >> setup.log
echo   node app.js >> setup.log
echo To monitor logs manually, check sent_logs.json or Discord channel. >> setup.log
echo.
echo To check if the webhook is running, use the following commands:
echo   cd D:\1WarcraftLOGSUPLOAD\WarcraftlogsDiscordWebhook-patch-2
echo   node app.js
echo To monitor logs manually, check sent_logs.json or Discord channel.
pause