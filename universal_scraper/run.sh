#!/bin/sh

# Load configuration from options.json
CONFIG_PATH=/data/options.json

# Extract configuration values
TELEGRAM_BOT_TOKEN=$(jq --raw-output '.telegram_bot_token' $CONFIG_PATH)
SCRAPE_INTERVAL=$(jq --raw-output '.scrape_interval_minutes' $CONFIG_PATH)
DATABASE_TYPE=$(jq --raw-output '.database_type' $CONFIG_PATH)
ADMIN_TOKEN=$(jq --raw-output '.admin_token' $CONFIG_PATH)
AZURE_BLOB_URL=$(jq --raw-output '.azure_blob_url' $CONFIG_PATH)

# Download database from Azure Blob Storage if it doesn't exist
if [ ! -f "/data/multiscraper.db" ] && [ ! -z "$AZURE_BLOB_URL" ] && [ "$AZURE_BLOB_URL" != "null" ]; then
    echo "Database not found. Downloading from Azure Blob Storage..."
    echo "Blob URL: ${AZURE_BLOB_URL:0:50}..."
    
    # Use curl to download the database file
    if curl -f -o "/data/multiscraper.db" "$AZURE_BLOB_URL"; then
        echo "Database downloaded successfully from Azure Blob Storage"
    else
        echo "Failed to download database from Azure Blob Storage"
        echo "Please check your azure_blob_url configuration"
    fi
else
    if [ -f "/data/multiscraper.db" ]; then
        echo "Database already exists, skipping download"
    else
        echo "Azure Blob Storage not configured or URL is empty"
        echo "azure_blob_url: $AZURE_BLOB_URL"
        echo "Creating empty database..."
        touch /data/multiscraper.db
    fi
fi

# Create .env file with configuration
cat > .env << EOL
# Bot configuratie
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
DEFAULT_SCRAPE_INTERVAL_MINUTES=${SCRAPE_INTERVAL}

# Database configuratie
DATABASE_TYPE=${DATABASE_TYPE}
DATABASE_PATH=/data/multiscraper.db

# Azure Blob Storage settings
AZURE_BLOB_URL=${AZURE_BLOB_URL}

# Admin token
ADMIN_TOKEN=${ADMIN_TOKEN}

# Network settings for container
NODE_TLS_REJECT_UNAUTHORIZED=0
EOL

# Create a simple web interface
cat > server.js << 'EOF'
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
            <strong>Database File:</strong> ${fs.existsSync('/data/multiscraper.db') ? '✅ Found' : '❌ Not found'}
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
        
        // Use axios to download with proper error handling
        const response = await axios({
            method: 'GET',
            url: process.env.AZURE_BLOB_URL,
            responseType: 'stream',
            timeout: 30000
        });
        
        const stream = fs.createWriteStream('/data/multiscraper.db');
        response.data.pipe(stream);
        
        stream.on('close', () => {
            res.json({ success: true, message: 'Database downloaded successfully!' });
        });
        
        stream.on('error', (err) => {
            res.json({ success: false, message: 'Failed to save database: ' + err.message });
        });
        
    } catch (error) {
        res.json({ success: false, message: 'Download failed: ' + error.message });
    }
});

app.get('/api/status', (req, res) => {
    res.json({
        status: 'running',
        config: {
            telegram: !!process.env.TELEGRAM_BOT_TOKEN,
            scrapeInterval: process.env.DEFAULT_SCRAPE_INTERVAL_MINUTES,
            databaseType: process.env.DATABASE_TYPE,
            databaseExists: fs.existsSync('/data/multiscraper.db'),
            azureConfigured: !!process.env.AZURE_BLOB_URL
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 Universal Scraper Dashboard running on port \${PORT}\`);
    console.log('📱 Accessible via Home Assistant ingress');
    
    // Test bot connection on startup
    testTelegramBot().then(result => {
        console.log('🤖 Telegram Bot Test:', result.message);
    });
});
EOF

echo "Configuration created. Starting web dashboard..."

# Start the web server
node server.js
