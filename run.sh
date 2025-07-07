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
    
    # Install Azure CLI
    apk add --no-cache azure-cli

    # Login to Azure using connection string
    export AZURE_STORAGE_CONNECTION_STRING

    # Download the database
    az storage blob download \
        --container-name "$AZURE_CONTAINER_NAME" \
        --name "$AZURE_BLOB_NAME" \
        --file "/data/multiscraper.db" \
        --output none

    if [ $? -eq 0 ]; then
        echo "Database downloaded successfully"
    else
        echo "Failed to download database from Azure Blob Storage"
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

# Web configuratie
WEB_URL=${WEB_URL}
ADMIN_TOKEN=${ADMIN_TOKEN}
EOL

# Install backend dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing backend dependencies..."
    npm install
fi

# Build backend if dist doesn't exist
if [ ! -d "dist" ]; then
    echo "Building backend..."
    npm run build
fi

# Install and build frontend
echo "Setting up frontend..."
cd front-end
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
fi

if [ ! -d "build" ]; then
    echo "Building frontend..."
    npm run build
fi

# Return to main directory
cd ..

# Install serve globally for frontend hosting
echo "Installing serve..."
npm install -g serve

# Start both applications
echo "Starting applications..."
# Start frontend server in the background using serve
cd front-end && serve -s build -l 3000 &
# Start backend
cd ..
node dist/index.js
