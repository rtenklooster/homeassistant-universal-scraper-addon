# Changelog

## 1.1.0

**🎯 SIMPLIFIED CONFIGURATION & PERSISTENT DATABASE**

- **SIMPLIFIED SETUP:** Removed `db_location` option - database always stored in `/config` directory
- **PERSISTENT DATABASE:** Database automatically persists across add-on updates and reinstalls
- **NO MORE CHOICES:** Eliminates configuration confusion - database always in the right place
- **HOME ASSISTANT INTEGRATION:** Database stored alongside configuration.yaml and automations.yaml
- **BACKUP FRIENDLY:** Database included in Home Assistant configuration backups automatically

**What changed:**
- Removed `db_location` configuration option from settings
- Database fixed to `/config/multiscraper.db` location
- Simplified startup script logic
- Cleaner configuration interface
- Better Home Assistant integration

**Benefits:**
- No more data loss from wrong database location choices
- Consistent with Home Assistant best practices
- Easier setup for new users
- Database automatically backed up with Home Assistant config

## 1.0.9

**🏠 DATABASE LOCATION & INTEGRITY IMPROVEMENTS**

- **DEFAULT CONFIG LOCATION:** Database now defaults to `/config` directory (same as configuration.yaml)
- **DATABASE PERSISTENCE:** Database survives add-on updates and reinstalls when stored in config directory
- **DATABASE INTEGRITY CHECK:** Added SQLite integrity validation before startup
- **AUTOMATIC BACKUP:** Corrupted databases are automatically backed up with timestamp
- **IMPROVED LOGIC:** Fixed database location logic to default to config directory
- **SQLITE TOOLS:** Added SQLite tools to Docker container for database operations

**Database Features:**
- Default location: `/config/multiscraper.db` (persistent across updates)
- Alternative location: `/data/multiscraper.db` (if specifically configured)
- Automatic integrity checks on startup
- Corrupted database backup and recovery
- Compatible with Home Assistant configuration management

## 1.0.8hangelog

## 1.0.9

**📁 DATABASE PERSISTENCE IMPROVEMENT**

- **DEFAULT DATABASE LOCATION:** Changed default database location from `data` to `config`
- **PERSISTENT STORAGE:** Database now stored in Home Assistant config directory by default
- **DATA SAFETY:** Database persists across add-on updates and reinstalls
- **CONFIGURATION CONSISTENCY:** Database stored alongside configuration.yaml and automations.yaml
- **USER EXPERIENCE:** No more data loss when updating the add-on

**Benefits:**
- Database is now stored in `/config/multiscraper.db` by default
- Survives add-on updates, container rebuilds, and Home Assistant restarts
- Consistent with Home Assistant best practices for persistent data
- Easy backup as part of Home Assistant configuration backup

## 1.0.8

**🛠️ BUILD OPTIMIZATION & STABILITY IMPROVEMENTS**

- **MEMORY OPTIMIZATION:** Added NODE_OPTIONS to handle memory constraints in Docker containers
- **BUILD RESILIENCE:** Enhanced React build process with fallback mechanisms for resource-constrained environments
- **FALLBACK UI:** Added fallback HTML interface when React build fails due to memory limitations
- **BACKEND FLEXIBILITY:** Improved backend build with ts-node fallback for TypeScript runtime execution
- **CHROMIUM SUPPORT:** Added Chromium browser support for web scraping functionality
- **STARTUP ROBUSTNESS:** Enhanced startup sequence with multiple fallback options
- **DOCKER OPTIMIZATION:** Improved Dockerfile with better memory management and essential dependencies
- **ERROR HANDLING:** Better error handling and recovery during build and startup processes

**Technical Improvements:**
- Set NODE_OPTIONS="--max-old-space-size=2048" for better memory management
- Added CI=false for React builds to reduce memory usage
- Chromium browser integration for web scraping
- Fallback HTML interface when React build fails
- ts-node runtime fallback for TypeScript execution
- Enhanced error messaging and debugging information

## 1.0.7

**🚀 MAJOR UPDATE: Complete Project Integration**

- **COMPLETE REWRITE:** Now downloads and runs the actual [Universal Scraper with Telegram Notifications](https://github.com/rtenklooster/Universal-scraper-with-telegram-notifications) project
- **FULL REACT FRONTEND:** Complete Material-UI React application with all original features
- **TYPESCRIPT BACKEND:** Full Express API server with TypeScript support
- **ALL SCRAPERS INCLUDED:** Lidl, Marktplaats, Vinted scrapers with full functionality
- **TELEGRAM BOT:** Interactive Telegram bot with search commands and user management
- **PRODUCT MANAGEMENT:** Complete product search, filtering, and notification system
- **USER SYSTEM:** Multi-user support with admin privileges and token management
- **REAL-TIME UPDATES:** Live scraping status and real-time notifications
- **PROFESSIONAL UI:** Complete rewrite from simple dashboard to full-featured application
- **PROJECT AUTHENTICITY:** Now runs the genuine project instead of a simplified version
- **AUTO-UPDATES:** Downloads latest project version on container start
- **BUILD SYSTEM:** Full npm build process with TypeScript compilation
- **DATABASE MIGRATION:** Automatic database setup and migration
- **ERROR HANDLING:** Comprehensive error handling and startup validation

**Breaking Changes:**
- Replaced simple web dashboard with complete React application
- Default scrape interval changed from 1 to 60 minutes (more reasonable)
- Requires Telegram bot token (mandatory for core functionality)
- Container now clones project from GitHub on startup

## 1.0.6

- **NEW FEATURE:** Added `force_db_download` option to always download database from Azure, even if it exists locally
- **NEW FEATURE:** Added `db_location` option to choose database storage location (`data` or `config`)
- **DATABASE FLEXIBILITY:** Database can now be stored in Home Assistant config directory (`/config/multiscraper.db`) for persistence across reinstalls
- **TELEGRAM FIX:** Enhanced Telegram bot token handling with better environment variable export and debugging
- **DASHBOARD IMPROVEMENTS:** Updated web dashboard to show new configuration options and database location
- **DEBUGGING:** Added comprehensive configuration debug output to help troubleshoot issues
- **CONFIG MAPPING:** Added `config:rw` mapping to support database storage in Home Assistant config directory
- **ENVIRONMENT VARIABLES:** Improved environment variable handling for better container compatibility

## 1.0.5

- **REBUILD FIX:** Force container rebuild to eliminate cached old versions
- Added build-time cache buster to Dockerfile to prevent old code execution
- Fixed persistent issues with old container versions running outdated scripts
- Ensured run.sh script is properly committed and not empty
- Force Home Assistant to rebuild container from scratch

## 1.0.4

- **CRITICAL FIX:** Fixed JavaScript syntax error in server.js causing container crashes
- Fixed template literal escaping issues in shell script
- Removed references to old Azure connection string configuration
- Fixed broken template literals that caused "Invalid or unexpected token" errors
- Properly escaped heredoc delimiters in run.sh script
- Ensured proper Node.js syntax for console.log statements

## 1.0.3

- **BREAKING:** Simplified Azure Blob configuration - now uses single URL with SAS token instead of connection string + container + blob name
- Fixed Telegram Bot connectivity issues in container environment
- Added Telegram Bot connection test in web dashboard
- Improved network settings for container (NODE_TLS_REJECT_UNAUTHORIZED=0)
- Better error handling and user feedback in web interface
- Simplified Azure Blob download using curl instead of Azure SDK
- Enhanced dashboard with bot testing functionality

## 1.0.2

- Fixed Docker build issues by removing Azure CLI dependency
- Simplified add-on to configuration-only mode
- Use @azure/storage-blob SDK for Azure Blob Storage operations
- Removed unnecessary build tools and frontend dependencies
- Improved reliability and faster container builds
- Add-on now focuses on configuration management and database sync

## 1.0.1

- Restructured repository for Home Assistant add-on compatibility
- Added proper repository.yaml and directory structure

## 1.0.0

- Initial release
- Universal web scraper with Telegram notifications
- Support for multiple architectures (aarch64, amd64, armhf, armv7, i386)
- SQLite and MSSQL database support
- Azure Blob Storage integration for database synchronization
- Web interface for configuration and monitoring
