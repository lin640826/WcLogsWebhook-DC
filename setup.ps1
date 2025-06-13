Write-Output "Warcraft Logs Discord Webhook Setup" | Tee-Object -FilePath "setup.log"
Write-Output "$(Get-Date)" | Tee-Object -FilePath "setup.log" -Append

# Set project directory
try {
    Set-Location -Path "D:\1WarcraftLOGSUPLOAD\WarcraftlogsDiscordWebhook-patch-2" -ErrorAction Stop
} catch {
    Write-Output "Failed to change to project directory. Please check the path." | Tee-Object -FilePath "setup.log" -Append
    Read-Host "Press Enter to exit"
    exit
}

# Prompt for custom Node.js path
$nodePath = Read-Host "Enter your Node.js installation path (e.g., D:\1WarcraftLOGSUPLOAD, or press Enter for default)"
if ($nodePath) {
    $env:PATH += ";$nodePath"
    Write-Output "Using custom Node.js path: $nodePath" | Tee-Object -FilePath "setup.log" -Append
}

# Check if Node.js is installed
try {
    $nodeVersion = node --version
    Write-Output "Node.js version: $nodeVersion" | Tee-Object -FilePath "setup.log" -Append
} catch {
    Write-Output "Node.js not found. Downloading and installing Node.js..." | Tee-Object -FilePath "setup.log" -Append
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.16.0/node-v22.16.0-x64.msi" -OutFile "node-installer.msi"
    Write-Output "Installing Node.js..." | Tee-Object -FilePath "setup.log" -Append
    Start-Process msiexec -ArgumentList "/i node-installer.msi /quiet" -Wait
    Remove-Item "node-installer.msi"
    Write-Output "Node.js installed. Please restart this script." | Tee-Object -FilePath "setup.log" -Append
    Read-Host "Press Enter to exit"
    exit
}

# Check if dependencies are installed
if (-not (Test-Path "node_modules")) {
    Write-Output "Installing dependencies..." | Tee-Object -FilePath "setup.log" -Append
    try {
        npm install
    } catch {
        Write-Output "Failed to install dependencies. Check npm logs." | Tee-Object -FilePath "setup.log" -Append
        Read-Host "Press Enter to exit"
        exit
    }
} else {
    Write-Output "Dependencies already installed." | Tee-Object -FilePath "setup.log" -Append
}

# Check if config.json exists
if (Test-Path "config.json") {
    $reconfigure = Read-Host "Config file found. Reconfigure Warcraft Logs ID and API Key? (y/n)"
    Write-Output "User input for reconfigure: $reconfigure" | Tee-Object -FilePath "setup.log" -Append
    if ($reconfigure -eq "y") {
        Write-Output "Enter your Warcraft Logs details." | Tee-Object -FilePath "setup.log" -Append
        $wclUserId = Read-Host "Enter your Warcraft Logs User ID"
        $wclApiKey = Read-Host "Enter your Warcraft Logs API Key"
        Write-Output "Writing config.json with ID: $wclUserId" | Tee-Object -FilePath "setup.log" -Append
        $config = @{
            wclUserId = $wclUserId
            wclApiKey = $wclApiKey
        }
        try {
            $config | ConvertTo-Json | Out-File -FilePath "config.json" -Encoding utf8
            Write-Output "Configuration updated." | Tee-Object -FilePath "setup.log" -Append
        } catch {
            Write-Output "Failed to write config.json. Check permissions: $_" | Tee-Object -FilePath "setup.log" -Append
            Read-Host "Press Enter to exit"
            exit
        }
    } else {
        Write-Output "Configuration already set in config.json." | Tee-Object -FilePath "setup.log" -Append
    }
} else {
    Write-Output "Config file not found. Please enter your Warcraft Logs details." | Tee-Object -FilePath "setup.log" -Append
    $wclUserId = Read-Host "Enter your Warcraft Logs User ID"
    $wclApiKey = Read-Host "Enter your Warcraft Logs API Key"
    Write-Output "Writing config.json with ID: $wclUserId" | Tee-Object -FilePath "setup.log" -Append
    $config = @{
        wclUserId = $wclUserId
        wclApiKey = $wclApiKey
    }
    try {
        $config | ConvertTo-Json | Out-File -FilePath "config.json" -Encoding utf8
        Write-Output "Configuration created." | Tee-Object -FilePath "setup.log" -Append
    } catch {
        Write-Output "Failed to write config.json. Check permissions: $_" | Tee-Object -FilePath "setup.log" -Append
        Read-Host "Press Enter to exit"
        exit
    }
}

# Pause to check configuration
Write-Output "Configuration complete. Press Enter to start the webhook..." | Tee-Object -FilePath "setup.log" -Append
Read-Host "Press Enter to start the webhook"

# Test run
Write-Output "Starting the webhook..." | Tee-Object -FilePath "setup.log" -Append
try {
    node app.js
} catch {
    Write-Output "Failed to start webhook. Check package.json or app.js: $_" | Tee-Object -FilePath "setup.log" -Append
    Read-Host "Press Enter to exit"
    exit
}

Write-Output "" | Tee-Object -FilePath "setup.log" -Append
Write-Output "To check if the webhook is running, use the following commands:" | Tee-Object -FilePath "setup.log" -Append
Write-Output "  cd D:\1WarcraftLOGSUPLOAD\WarcraftlogsDiscordWebhook-patch-2" | Tee-Object -FilePath "setup.log" -Append
Write-Output "  node app.js" | Tee-Object -FilePath "setup.log" -Append
Write-Output "To monitor logs manually, check sent_logs.json or Discord channel." | Tee-Object -FilePath "setup.log" -Append
Read-Host "Press Enter to continue"