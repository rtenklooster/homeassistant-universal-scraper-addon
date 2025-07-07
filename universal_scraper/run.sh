#!/bin/sh

# Universal Scraper with Telegram Notifications - Home Assistant Add-on
# This script downloads and runs the actual project from GitHub

echo "🚀 Starting Universal Scraper with Telegram Notifications"
echo "================================================================="

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

# Verify Telegram bot token is set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "null" ] || [ "$TELEGRAM_BOT_TOKEN" = "" ]; then
    echo "❌ ERROR: Telegram bot token is not set or empty!"
    echo "Please configure telegram_bot_token in the add-on configuration"
    exit 1
else
    echo "✅ Telegram bot token is configured (${#TELEGRAM_BOT_TOKEN} characters)"
fi

# Set database path based on location preference
if [ "$DB_LOCATION" = "config" ]; then
    DB_PATH="/config/multiscraper.db"
    DB_DIR="/config"
    echo "📁 Database will be stored in Home Assistant config directory: $DB_PATH"
else
    DB_PATH="/data/multiscraper.db"
    DB_DIR="/data"
    echo "📁 Database will be stored in add-on data directory: $DB_PATH"
fi

# Ensure the database directory exists
mkdir -p "$DB_DIR"

# Download database from Azure Blob Storage if needed
download_needed=false

if [ "$FORCE_DB_DOWNLOAD" = "true" ]; then
    echo "🔄 Force download enabled - will download database regardless of existing file"
    download_needed=true
elif [ ! -f "$DB_PATH" ]; then
    echo "📥 Database not found at $DB_PATH - will download if Azure URL is configured"
    download_needed=true
else
    echo "✅ Database already exists at $DB_PATH and force download is disabled"
fi

if [ "$download_needed" = "true" ] && [ ! -z "$AZURE_BLOB_URL" ] && [ "$AZURE_BLOB_URL" != "null" ] && [ "$AZURE_BLOB_URL" != "" ]; then
    echo "📥 Downloading database from Azure Blob Storage..."
    echo "Blob URL: ${AZURE_BLOB_URL:0:50}..."
    
    if curl -f -o "$DB_PATH" "$AZURE_BLOB_URL"; then
        echo "✅ Database downloaded successfully from Azure Blob Storage to $DB_PATH"
    else
        echo "❌ Failed to download database from Azure Blob Storage"
        echo "Please check your azure_blob_url configuration"
    fi
elif [ "$download_needed" = "true" ]; then
    echo "ℹ️  Azure Blob Storage not configured or URL is empty"
    echo "Database will be created automatically by the application"
fi

# Clone or update the Universal Scraper project
PROJECT_DIR="/usr/src/app/project"
REPO_URL="https://github.com/rtenklooster/Universal-scraper-with-telegram-notifications.git"

echo "📦 Setting up Universal Scraper project..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo "📥 Cloning Universal Scraper project from GitHub..."
    git clone "$REPO_URL" "$PROJECT_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to clone project from GitHub"
        exit 1
    fi
    echo "✅ Project cloned successfully"
else
    echo "🔄 Project directory exists, pulling latest changes..."
    cd "$PROJECT_DIR"
    git pull origin main
    echo "✅ Project updated"
fi

# Change to project directory
cd "$PROJECT_DIR"

# Create .env file for the project
echo "⚙️  Creating environment configuration..."
cat > .env << EOL
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}

# Scraping Configuration
DEFAULT_SCRAPE_INTERVAL_MINUTES=${SCRAPE_INTERVAL}

# Database Configuration
DATABASE_TYPE=${DATABASE_TYPE}
DATABASE_PATH=${DB_PATH}

# Web Interface Configuration (Home Assistant ingress port)
WEB_URL=http://localhost:3000
ADMIN_TOKEN=${ADMIN_TOKEN}

# Logging Configuration
LOG_LEVEL=info

# Proxy Configuration (disabled for Home Assistant)
USE_ROTATING_PROXY=false
PROXY_URL=

# Additional Add-on specific settings
AZURE_BLOB_URL=${AZURE_BLOB_URL}
FORCE_DB_DOWNLOAD=${FORCE_DB_DOWNLOAD}
DB_LOCATION=${DB_LOCATION}

# Server Configuration - Use port 3000 for Home Assistant ingress
PORT=3000
NODE_ENV=production
EOL

echo "✅ Environment file created"

# Install project dependencies
echo "📦 Installing project dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed successfully"

# Build the React frontend first
echo "🔨 Building React frontend..."
cd front-end
npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install frontend dependencies"
    exit 1
fi

npm run build
if [ $? -ne 0 ]; then
    echo "❌ Failed to build frontend"
    exit 1
fi
echo "✅ Frontend built successfully"

# Go back to project root
cd ..

# Build the backend
echo "🔨 Building backend..."
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Failed to build backend"
    exit 1
fi
echo "✅ Backend built successfully"

# Ensure the logs directory exists
mkdir -p logs

# Patch the server to use PORT environment variable for Home Assistant ingress
echo "🔧 Patching server to use PORT environment variable..."
if [ -f "src/index.ts" ]; then
    # Replace hardcoded port 3001 with environment variable PORT or 3000
    sed -i 's/const port = 3001;/const port = parseInt(process.env.PORT || "3000", 10);/' src/index.ts
    
    # Also try to patch the built JavaScript file if it exists
    if [ -f "dist/index.js" ]; then
        sed -i 's/const port = 3001;/const port = parseInt(process.env.PORT || "3000", 10);/' dist/index.js
    fi
    
    # Patch to serve React build as static files
    echo "🔧 Patching server to serve React frontend..."
    
    # Add express static serving for React build
    cat >> src/index.ts << 'EOF'

// Serve React frontend static files (added by Home Assistant add-on)
app.use(express.static(path.join(__dirname, '../front-end/build')));

// Serve index.html for all other routes (React Router support)
app.get('*', (req: Request, res: Response) => {
  res.sendFile(path.join(__dirname, '../front-end/build/index.html'));
});
EOF
    
    echo "✅ Server patched to use configurable port and serve React frontend"
else
    echo "❌ Could not find src/index.ts to patch"
fi

# Export environment variables for the application
export TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
export DEFAULT_SCRAPE_INTERVAL_MINUTES="$SCRAPE_INTERVAL"
export DATABASE_TYPE="$DATABASE_TYPE"
export DATABASE_PATH="$DB_PATH"
export WEB_URL="http://localhost:3000"
export ADMIN_TOKEN="$ADMIN_TOKEN"
export LOG_LEVEL="info"
export USE_ROTATING_PROXY="false"
export PROXY_URL=""
export AZURE_BLOB_URL="$AZURE_BLOB_URL"
export FORCE_DB_DOWNLOAD="$FORCE_DB_DOWNLOAD"
export DB_LOCATION="$DB_LOCATION"
export PORT="3000"
export NODE_ENV="production"

echo "✅ Environment variables exported"

echo "================================================================="
echo "🚀 Starting Universal Scraper with Telegram Notifications..."
echo "================================================================="
echo "📱 Telegram Bot: Enabled"
echo "🌐 Web Interface: http://localhost:3000 (Home Assistant Ingress)"
echo "📊 API Server: http://localhost:3000"
echo "💾 Database: $DB_PATH"
echo "🔄 Scrape Interval: $SCRAPE_INTERVAL minutes"
echo "================================================================="

# Start the application
npm start
