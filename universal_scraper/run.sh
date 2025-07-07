#!/bin/sh

# Load configuration from options.json
CONFIG_PATH=/data/options.json

# Extract configuration values
TELEGRAM_BOT_TOKEN=$(jq --raw-output '.telegram_bot_token' $CONFIG_PATH)
SCRAPE_INTERVAL=$(jq --raw-output '.scrape_interval_minutes' $CONFIG_PATH)
DATABASE_TYPE=$(jq --raw-output '.database_type' $CONFIG_PATH)
ADMIN_TOKEN=$(jq --raw-output '.admin_token' $CONFIG_PATH)
AZURE_BLOB_URL=$(jq --raw-output '.azure_blob_url' $CONFIG_PATH)
FORCE_DB_DOWNLOAD=$(jq --raw-output '.force_db_download' $CONFIG_PATH)
DB_LOCATION=$(jq --raw-output '.db_location' $CONFIG_PATH)

# Debug configuration values
echo "=== Configuration Debug ==="
echo "TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:0:10}..." 
echo "SCRAPE_INTERVAL: $SCRAPE_INTERVAL"
echo "DATABASE_TYPE: $DATABASE_TYPE"
echo "ADMIN_TOKEN: ${ADMIN_TOKEN:0:10}..."
echo "AZURE_BLOB_URL: ${AZURE_BLOB_URL:0:50}..."
echo "FORCE_DB_DOWNLOAD: $FORCE_DB_DOWNLOAD"
echo "DB_LOCATION: $DB_LOCATION"
echo "=========================="

# Set database path based on location preference
if [ "$DB_LOCATION" = "config" ]; then
    DB_PATH="/config/multiscraper.db"
    echo "Database will be stored in Home Assistant config directory: $DB_PATH"
else
    DB_PATH="/data/multiscraper.db"
    echo "Database will be stored in add-on data directory: $DB_PATH"
fi

# Ensure the database directory exists
DB_DIR=$(dirname "$DB_PATH")
mkdir -p "$DB_DIR"

# Download database from Azure Blob Storage
download_needed=false

if [ "$FORCE_DB_DOWNLOAD" = "true" ]; then
    echo "Force download enabled - will download database regardless of existing file"
    download_needed=true
elif [ ! -f "$DB_PATH" ]; then
    echo "Database not found at $DB_PATH - will download if Azure URL is configured"
    download_needed=true
else
    echo "Database already exists at $DB_PATH and force download is disabled"
fi

if [ "$download_needed" = "true" ] && [ ! -z "$AZURE_BLOB_URL" ] && [ "$AZURE_BLOB_URL" != "null" ] && [ "$AZURE_BLOB_URL" != "" ]; then
    echo "Downloading database from Azure Blob Storage..."
    echo "Blob URL: ${AZURE_BLOB_URL:0:50}..."
    
    # Use curl to download the database file
    if curl -f -o "$DB_PATH" "$AZURE_BLOB_URL"; then
        echo "Database downloaded successfully from Azure Blob Storage to $DB_PATH"
    else
        echo "Failed to download database from Azure Blob Storage"
        echo "Please check your azure_blob_url configuration"
        # Create empty database if download fails
        touch "$DB_PATH"
    fi
elif [ "$download_needed" = "true" ]; then
    echo "Azure Blob Storage not configured or URL is empty"
    echo "azure_blob_url: $AZURE_BLOB_URL"
    echo "Creating empty database at $DB_PATH..."
    touch "$DB_PATH"
fi

# Create .env file with configuration
cat > .env << EOL
# Bot configuratie
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
DEFAULT_SCRAPE_INTERVAL_MINUTES=${SCRAPE_INTERVAL}

# Database configuratie
DATABASE_TYPE=${DATABASE_TYPE}
DATABASE_PATH=${DB_PATH}

# Azure Blob Storage settings
AZURE_BLOB_URL=${AZURE_BLOB_URL}

# Admin token
ADMIN_TOKEN=${ADMIN_TOKEN}

# Force download setting
FORCE_DB_DOWNLOAD=${FORCE_DB_DOWNLOAD}

# Database location
DB_LOCATION=${DB_LOCATION}
EOL

echo "Environment file created with database path: $DB_PATH"

# Export environment variables for the application
export TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
export DEFAULT_SCRAPE_INTERVAL_MINUTES="$SCRAPE_INTERVAL"
export DATABASE_TYPE="$DATABASE_TYPE"
export DATABASE_PATH="$DB_PATH"
export AZURE_BLOB_URL="$AZURE_BLOB_URL"
export ADMIN_TOKEN="$ADMIN_TOKEN"
export FORCE_DB_DOWNLOAD="$FORCE_DB_DOWNLOAD"
export DB_LOCATION="$DB_LOCATION"

echo "Environment variables exported"

# Verify Telegram bot token is set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "null" ] || [ "$TELEGRAM_BOT_TOKEN" = "" ]; then
    echo "WARNING: Telegram bot token is not set or empty!"
    echo "Please configure telegram_bot_token in the add-on configuration"
else
    echo "Telegram bot token is configured (${#TELEGRAM_BOT_TOKEN} characters)"
fi

# Network settings for container
NODE_TLS_REJECT_UNAUTHORIZED=0
EOL

# Create a simple web interface
cat > server.js << 'SERVEREOF'
const express = require('express');
const fs = require('fs');
const https = require('https');
const axios = require('axios');

const app = express();
const PORT = 3000;

// Parse JSON bodies
app.use(express.json());
app.use(express.static('public'));

// Test Telegram Bot connectivity
async function testTelegramBot() {
    if (!process.env.TELEGRAM_BOT_TOKEN) {
        return { success: false, message: 'No bot token configured' };
    }
    
    try {
        const response = await axios.get(`https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/getMe`, {
            timeout: 10000,
            httpsAgent: new https.Agent({
                rejectUnauthorized: false
            })
        });
        
        if (response.data.ok) {
            return { 
                success: true, 
                message: `Bot connected: @${response.data.result.username}`,
                botInfo: response.data.result
            };
        } else {
            return { success: false, message: 'Bot API call failed' };
        }
    } catch (error) {
        return { 
            success: false, 
            message: `Bot connection failed: ${error.message}` 
        };
    }
}

// Basic HTML interface
const html = `
<!DOCTYPE html>
<html>
<head>
    <title>Universal Scraper Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { padding: 10px; margin: 10px 0; border-radius: 4px; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; }
        .error { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; }
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .config-item { margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 4px; }
        .btn { background: #007bff; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        .btn:hover { background: #0056b3; }
        .loading { opacity: 0.7; pointer-events: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Universal Scraper Dashboard</h1>
        
        <div class="status success">
            <strong>✅ Add-on is running!</strong>
        </div>
        
        <h2>📋 Configuration</h2>
        <div class="config-item">
            <strong>Telegram Bot:</strong> ${process.env.TELEGRAM_BOT_TOKEN ? '🔑 Token configured' : '❌ Not configured'}
        </div>
        <div class="config-item">
            <strong>Scrape Interval:</strong> ${process.env.DEFAULT_SCRAPE_INTERVAL_MINUTES || 'Not set'} minutes
        </div>
        <div class="config-item">
            <strong>Database Type:</strong> ${process.env.DATABASE_TYPE || 'Not set'}
        </div>
        <div class="config-item">
            <strong>Database File:</strong> ${fs.existsSync(process.env.DATABASE_PATH || '/data/multiscraper.db') ? '✅ Found at ' + (process.env.DATABASE_PATH || '/data/multiscraper.db') : '❌ Not found'}
        </div>
        <div class="config-item">
            <strong>Database Location:</strong> ${process.env.DB_LOCATION === 'config' ? '🏠 Home Assistant Config' : '📁 Add-on Data'} (${process.env.DATABASE_PATH || '/data/multiscraper.db'})
        </div>
        <div class="config-item">
            <strong>Force Download:</strong> ${process.env.FORCE_DB_DOWNLOAD === 'true' ? '✅ Enabled' : '❌ Disabled'}
        </div>
        <div class="config-item">
            <strong>Azure Blob URL:</strong> ${process.env.AZURE_BLOB_URL ? '✅ Configured' : '❌ Not configured'}
        </div>
        
        <h2>🤖 Telegram Bot Status</h2>
        <div id="bot-status">
            <div class="status info">Click "Test Bot" to check connection...</div>
        </div>
        
        <h2>📊 Actions</h2>
        <button class="btn" onclick="testBot()">🤖 Test Telegram Bot</button>
        <button class="btn" onclick="downloadDatabase()">📥 Download Database from Azure</button>
        <button class="btn" onclick="showLogs()">📝 Show Logs</button>
        
        <div id="result" style="margin-top: 20px;"></div>
        
        <script>
            function testBot() {
                const btn = event.target;
                btn.classList.add('loading');
                btn.textContent = '🔄 Testing...';
                
                fetch('/api/test-bot', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        const statusDiv = document.getElementById('bot-status');
                        statusDiv.innerHTML = 
                            '<div class="status ' + (data.success ? 'success' : 'error') + '">' + 
                            (data.success ? '✅ ' : '❌ ') + data.message + '</div>';
                        
                        btn.classList.remove('loading');
                        btn.textContent = '🤖 Test Telegram Bot';
                    })
                    .catch(err => {
                        document.getElementById('bot-status').innerHTML = 
                            '<div class="status error">❌ Test failed: ' + err.message + '</div>';
                        btn.classList.remove('loading');
                        btn.textContent = '🤖 Test Telegram Bot';
                    });
            }
            
            function downloadDatabase() {
                const btn = event.target;
                btn.classList.add('loading');
                btn.textContent = '📥 Downloading...';
                
                document.getElementById('result').innerHTML = '<div class="status info">Downloading database...</div>';
                fetch('/api/download-db', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        document.getElementById('result').innerHTML = 
                            '<div class="status ' + (data.success ? 'success' : 'error') + '">' + data.message + '</div>';
                        
                        btn.classList.remove('loading');
                        btn.textContent = '📥 Download Database from Azure';
                    })
                    .catch(err => {
                        document.getElementById('result').innerHTML = 
                            '<div class="status error">Download failed: ' + err.message + '</div>';
                        btn.classList.remove('loading');
                        btn.textContent = '📥 Download Database from Azure';
                    });
            }
            
            function showLogs() {
                document.getElementById('result').innerHTML = '<div class="status info">Feature coming soon...</div>';
            }
        </script>
    </div>
</body>
</html>
`;

// Routes
app.get('/', (req, res) => {
    res.send(html);
});

app.post('/api/test-bot', async (req, res) => {
    const result = await testTelegramBot();
    res.json(result);
});

app.post('/api/download-db', async (req, res) => {
    try {
        if (!process.env.AZURE_BLOB_URL || process.env.AZURE_BLOB_URL === 'null') {
            return res.json({ success: false, message: 'Azure Blob URL not configured' });
        }
        
        const dbPath = process.env.DATABASE_PATH || '/data/multiscraper.db';
        
        // Use axios to download with proper error handling
        const response = await axios({
            method: 'GET',
            url: process.env.AZURE_BLOB_URL,
            responseType: 'stream',
            timeout: 30000
        });
        
        const stream = fs.createWriteStream(dbPath);
        response.data.pipe(stream);
        
        stream.on('close', () => {
            res.json({ success: true, message: `Database downloaded successfully to ${dbPath}!` });
        });
        
        stream.on('error', (err) => {
            res.json({ success: false, message: 'Failed to save database: ' + err.message });
        });
        
    } catch (error) {
        res.json({ success: false, message: 'Download failed: ' + error.message });
    }
});

app.get('/api/status', (req, res) => {
    const dbPath = process.env.DATABASE_PATH || '/data/multiscraper.db';
    res.json({
        status: 'running',
        config: {
            telegram: !!process.env.TELEGRAM_BOT_TOKEN,
            scrapeInterval: process.env.DEFAULT_SCRAPE_INTERVAL_MINUTES,
            databaseType: process.env.DATABASE_TYPE,
            databaseExists: fs.existsSync(dbPath),
            databasePath: dbPath,
            azureConfigured: !!process.env.AZURE_BLOB_URL,
            forceDownload: process.env.FORCE_DB_DOWNLOAD === 'true',
            dbLocation: process.env.DB_LOCATION
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log('🚀 Universal Scraper Dashboard running on port ' + PORT);
    console.log('📱 Accessible via Home Assistant ingress');
    
    // Test bot connection on startup
    testTelegramBot().then(result => {
        console.log('🤖 Telegram Bot Test:', result.message);
    });
});
SERVEREOF

echo "Configuration created. Starting web dashboard..."

# Start the web server
node server.js
