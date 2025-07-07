# Changelog

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
