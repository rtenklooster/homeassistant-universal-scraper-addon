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

# Debug configuration values
echo "=== Configuration Debug ==="
echo "TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN:0:10}..." 
echo "SCRAPE_INTERVAL: $SCRAPE_INTERVAL"
echo "DATABASE_TYPE: $DATABASE_TYPE"
echo "ADMIN_TOKEN: ${ADMIN_TOKEN:0:10}..."
echo "AZURE_BLOB_URL: ${AZURE_BLOB_URL:0:50}..."
echo "FORCE_DB_DOWNLOAD: $FORCE_DB_DOWNLOAD"
echo "=========================="

# Verify Telegram bot token is set
if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ "$TELEGRAM_BOT_TOKEN" = "null" ] || [ "$TELEGRAM_BOT_TOKEN" = "" ]; then
    echo "❌ ERROR: Telegram bot token is not set or empty!"
    echo "Please configure telegram_bot_token in the add-on configuration"
    exit 1
else
    echo "✅ Telegram bot token is configured (${#TELEGRAM_BOT_TOKEN} characters)"
fi

# Database will always be stored in Home Assistant config directory
DB_PATH="/config/multiscraper.db"
DB_DIR="/config"
echo "📁 Database will be stored in Home Assistant config directory: $DB_PATH"

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
    
    # Remove existing database if it exists to prevent conflicts
    if [ -f "$DB_PATH" ]; then
        echo "🗑️ Removing existing database before download..."
        rm "$DB_PATH"
    fi
    
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

# Set Node options to prevent memory issues in Docker
export NODE_OPTIONS="--max-old-space-size=2048 --no-experimental-fetch"

npm install
if [ $? -ne 0 ]; then
    echo "❌ Failed to install frontend dependencies"
    exit 1
fi

# Try to build with memory optimizations
echo "🔨 Attempting React build with memory optimizations..."
npm run build
if [ $? -ne 0 ]; then
    echo "⚠️ React build failed - this is often due to memory constraints in Docker"
    echo "🔄 Attempting alternative build approach..."
    
    # Try with reduced parallelism
    export CI=false
    npm run build
    
    if [ $? -ne 0 ]; then
        echo "⚠️ React build still failing - the backend will serve a basic interface"
        echo "💡 The application will still work, but with a simplified UI"
        
        # Create a basic index.html as fallback
        mkdir -p build/static/js build/static/css
        cat > build/index.html << 'FALLBACK_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Universal Scraper</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { padding: 15px; background: #e7f3ff; border: 1px solid #bee5eb; border-radius: 4px; margin: 20px 0; }
        .api-link { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 10px 5px; }
        .api-link:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Universal Scraper with Telegram</h1>
        <div class="status">
            <h3>✅ Service Running</h3>
            <p>The Universal Scraper backend is running successfully. The React frontend failed to build due to memory constraints, but all core functionality is available via the API.</p>
        </div>
        <h3>📡 API Endpoints</h3>
        <a href="/api/products" class="api-link">View Products</a>
        <a href="/api/status" class="api-link">Service Status</a>
        <a href="/api/health" class="api-link">Health Check</a>
        <h3>📱 Telegram Bot</h3>
        <p>The Telegram bot is running and ready to receive commands. Send messages to your configured bot to interact with the scraper.</p>
        <h3>🔧 Full Interface</h3>
        <p>For the complete React interface, try building the add-on with more memory allocated to the container, or access the application directly via the backend API.</p>
    </div>
</body>
</html>
FALLBACK_HTML
        echo "📄 Created fallback HTML interface"
    else
        echo "✅ React build succeeded on second attempt"
    fi
else
    echo "✅ React frontend built successfully"
fi

# Go back to project root
cd ..

# Build the backend
echo "🔨 Building backend..."
npm run build
if [ $? -ne 0 ]; then
    echo "⚠️ TypeScript build failed - attempting to run with ts-node..."
    # Install ts-node if backend build fails
    npm install -g ts-node
    if [ $? -eq 0 ]; then
        echo "✅ ts-node installed as fallback"
    else
        echo "❌ Failed to install ts-node fallback"
        exit 1
    fi
else
    echo "✅ Backend built successfully"
fi

# Ensure the logs directory exists
mkdir -p logs

# Check database integrity and fix if needed
if [ -f "$DB_PATH" ]; then
    echo "🔍 Checking database integrity..."
    
    # Simple SQLite integrity check
    if ! sqlite3 "$DB_PATH" "PRAGMA integrity_check;" > /dev/null 2>&1; then
        echo "⚠️ Database integrity check failed - creating backup and starting fresh"
        mv "$DB_PATH" "${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "📦 Old database backed up with timestamp"
    else
        echo "✅ Database integrity check passed"
    fi
fi

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

# Start the application with fallback options
if [ -f "dist/index.js" ]; then
    echo "🚀 Starting compiled application..."
    npm start
elif [ -f "src/index.ts" ]; then
    echo "🚀 Starting with ts-node (TypeScript runtime)..."
    npx ts-node src/index.ts
else
    echo "❌ No entry point found - neither dist/index.js nor src/index.ts exists"
    exit 1
fi
