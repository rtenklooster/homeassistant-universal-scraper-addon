#!/bin/sh

# Load configuration from options.json
CONFIG_PATH=/data/options.json

# Extract configuration values
TELEGRAM_BOT_TOKEN=$(jq --raw-output '.telegram_bot_token' $CONFIG_PATH)
SCRAPE_INTERVAL=$(jq --raw-output '.scrape_interval_minutes' $CONFIG_PATH)
DATABASE_TYPE=$(jq --raw-output '.database_type' $CONFIG_PATH)
WEB_URL=$(jq --raw-output '.web_url' $CONFIG_PATH)
ADMIN_TOKEN=$(jq --raw-output '.admin_token' $CONFIG_PATH)
AZURE_STORAGE_CONNECTION_STRING=$(jq --raw-output '.azure_storage_connection_string' $CONFIG_PATH)
AZURE_CONTAINER_NAME=$(jq --raw-output '.azure_container_name' $CONFIG_PATH)
AZURE_BLOB_NAME=$(jq --raw-output '.azure_blob_name' $CONFIG_PATH)

# Download database from Azure Blob Storage if it doesn't exist
if [ ! -f "/data/multiscraper.db" ] && [ ! -z "$AZURE_STORAGE_CONNECTION_STRING" ] && [ ! -z "$AZURE_CONTAINER_NAME" ] && [ ! -z "$AZURE_BLOB_NAME" ]; then
    echo "Database not found. Downloading from Azure Blob Storage..."
    echo "Container: $AZURE_CONTAINER_NAME"
    echo "Blob: $AZURE_BLOB_NAME"
    echo "Connection string length: ${#AZURE_STORAGE_CONNECTION_STRING}"
    
    # Use Node.js with Azure SDK instead of CLI
    node -e "
    const { BlobServiceClient } = require('@azure/storage-blob');
    const fs = require('fs');
    
    async function downloadBlob() {
        try {
            console.log('Attempting to connect to Azure Blob Storage...');
            const connectionString = '$AZURE_STORAGE_CONNECTION_STRING';
            
            if (!connectionString || connectionString === 'null' || connectionString === '') {
                console.error('Azure Storage connection string is empty or invalid');
                console.error('Please configure azure_storage_connection_string in Home Assistant add-on configuration');
                process.exit(1);
            }
            
            console.log('Connection string format check...');
            if (!connectionString.includes('DefaultEndpointsProtocol') && !connectionString.includes('BlobEndpoint')) {
                console.error('Invalid connection string format. Expected format:');
                console.error('DefaultEndpointsProtocol=https;AccountName=<account>;AccountKey=<key>;EndpointSuffix=core.windows.net');
                console.error('Or with SAS token:');
                console.error('BlobEndpoint=https://<account>.blob.core.windows.net/;SharedAccessSignature=<sas-token>');
                process.exit(1);
            }
            
            const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
            const containerClient = blobServiceClient.getContainerClient('$AZURE_CONTAINER_NAME');
            const blobClient = containerClient.getBlobClient('$AZURE_BLOB_NAME');
            
            console.log('Downloading blob...');
            const response = await blobClient.download();
            const stream = fs.createWriteStream('/data/multiscraper.db');
            response.readableStreamBody.pipe(stream);
            
            stream.on('close', () => {
                console.log('Database downloaded successfully');
                process.exit(0);
            });
            
            stream.on('error', (err) => {
                console.error('Failed to write database file:', err);
                process.exit(1);
            });
        } catch (error) {
            console.error('Failed to download database from Azure Blob Storage:', error.message);
            console.error('Please check your Azure Storage configuration:');
            console.error('1. azure_storage_connection_string - Must be a valid Azure Storage connection string');
            console.error('2. azure_container_name - Must be an existing container name');
            console.error('3. azure_blob_name - Must be an existing blob file name');
            process.exit(1);
        }
    }
    
    downloadBlob();
    "
else
    if [ -f "/data/multiscraper.db" ]; then
        echo "Database already exists, skipping download"
    else
        echo "Azure Blob Storage not configured or missing parameters:"
        echo "- azure_storage_connection_string: ${#AZURE_STORAGE_CONNECTION_STRING} characters"
        echo "- azure_container_name: $AZURE_CONTAINER_NAME"  
        echo "- azure_blob_name: $AZURE_BLOB_NAME"
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
AZURE_STORAGE_CONNECTION_STRING=${AZURE_STORAGE_CONNECTION_STRING}
AZURE_CONTAINER_NAME=${AZURE_CONTAINER_NAME}
AZURE_BLOB_NAME=${AZURE_BLOB_NAME}

# Admin token
ADMIN_TOKEN=${ADMIN_TOKEN}
EOL

# Create a simple web interface
cat > server.js << 'EOF'
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

// Parse JSON bodies
app.use(express.json());
app.use(express.static('public'));

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
        .info { background: #d1ecf1; border: 1px solid #bee5eb; color: #0c5460; }
        .config-item { margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 4px; }
        .btn { background: #007bff; color: white; padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; }
        .btn:hover { background: #0056b3; }
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
            <strong>Telegram Bot:</strong> ${process.env.TELEGRAM_BOT_TOKEN ? '✅ Configured' : '❌ Not configured'}
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
            <strong>Azure Storage:</strong> ${process.env.AZURE_STORAGE_CONNECTION_STRING ? '✅ Configured' : '❌ Not configured'}
        </div>
        
        <h2>📊 Actions</h2>
        <button class="btn" onclick="downloadDatabase()">📥 Download Database from Azure</button>
        <button class="btn" onclick="showLogs()">📝 Show Logs</button>
        
        <div id="result" style="margin-top: 20px;"></div>
        
        <script>
            function downloadDatabase() {
                document.getElementById('result').innerHTML = '<div class="status info">Downloading database...</div>';
                fetch('/api/download-db', { method: 'POST' })
                    .then(response => response.json())
                    .then(data => {
                        document.getElementById('result').innerHTML = 
                            '<div class="status ' + (data.success ? 'success' : 'error') + '">' + data.message + '</div>';
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

app.post('/api/download-db', async (req, res) => {
    try {
        if (!process.env.AZURE_STORAGE_CONNECTION_STRING) {
            return res.json({ success: false, message: 'Azure Storage not configured' });
        }
        
        const { BlobServiceClient } = require('@azure/storage-blob');
        const blobServiceClient = BlobServiceClient.fromConnectionString(process.env.AZURE_STORAGE_CONNECTION_STRING);
        const containerClient = blobServiceClient.getContainerClient(process.env.AZURE_CONTAINER_NAME);
        const blobClient = containerClient.getBlobClient(process.env.AZURE_BLOB_NAME);
        
        const response = await blobClient.download();
        const stream = fs.createWriteStream('/data/multiscraper.db');
        response.readableStreamBody.pipe(stream);
        
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
            azureConfigured: !!process.env.AZURE_STORAGE_CONNECTION_STRING
        }
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(\`🚀 Universal Scraper Dashboard running on port \${PORT}\`);
    console.log('📱 Accessible via Home Assistant ingress');
});
EOF

echo "Configuration created. Starting web dashboard..."

# Start the web server
node server.js
