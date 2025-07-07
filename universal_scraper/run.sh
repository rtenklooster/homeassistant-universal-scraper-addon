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
    
    # Use Node.js with Azure SDK instead of CLI
    node -e "
    const { BlobServiceClient } = require('@azure/storage-blob');
    const fs = require('fs');
    
    async function downloadBlob() {
        try {
            const blobServiceClient = BlobServiceClient.fromConnectionString('$AZURE_STORAGE_CONNECTION_STRING');
            const containerClient = blobServiceClient.getContainerClient('$AZURE_CONTAINER_NAME');
            const blobClient = containerClient.getBlobClient('$AZURE_BLOB_NAME');
            
            const response = await blobClient.download();
            const stream = fs.createWriteStream('/data/multiscraper.db');
            response.readableStreamBody.pipe(stream);
            
            stream.on('close', () => {
                console.log('Database downloaded successfully');
                process.exit(0);
            });
            
            stream.on('error', (err) => {
                console.error('Failed to download database:', err);
                process.exit(1);
            });
        } catch (error) {
            console.error('Failed to download database from Azure Blob Storage:', error);
            process.exit(1);
        }
    }
    
    downloadBlob();
    "
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

# Web configuratie
WEB_URL=${WEB_URL}
ADMIN_TOKEN=${ADMIN_TOKEN}
EOL

echo "Configuration created. Starting application..."

# Keep container running with a simple message
echo "Universal Scraper add-on is ready!"
echo "Configuration loaded from Home Assistant"
echo "Telegram Bot Token: ${TELEGRAM_BOT_TOKEN:0:10}..."
echo "Scrape Interval: ${SCRAPE_INTERVAL} minutes"
echo "Database Type: ${DATABASE_TYPE}"

# Keep the container alive
tail -f /dev/null
