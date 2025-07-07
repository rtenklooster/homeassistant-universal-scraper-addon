# Home Assistant Add-on: Universal Scraper with Telegram

Universal web scraper with Telegram notifications for Home Assistant.

## About

This add-on allows you to scrape various websites and receive notifications through Telegram. It supports multiple retailers and can be configured to monitor product availability and price changes.

## Installation

1. Add this repository to your Home Assistant instance.
2. Install the "Universal Scraper with Telegram" add-on.
3. Configure the add-on (see configuration below).

## Configuration

Example configuration:

```yaml
telegram_bot_token: "YOUR_BOT_TOKEN"
scrape_interval_minutes: 1
database_type: "sqlite"
web_url: "http://homeassistant:3000"
admin_token: "YOUR_ADMIN_TOKEN"
azure_storage_connection_string: "YOUR_AZURE_STORAGE_CONNECTION_STRING"
azure_container_name: "YOUR_CONTAINER_NAME"
azure_blob_name: "multiscraper.db"
```

### Required Configuration

| Option | Description |
|--------|------------|
| `telegram_bot_token` | Your Telegram Bot Token |
| `scrape_interval_minutes` | Interval between scrapes in minutes |
| `database_type` | Database type (sqlite or mssql) |
| `web_url` | URL where the web interface will be available |
| `admin_token` | Admin token for API authentication |
| `azure_storage_connection_string` | Azure Storage connection string for database sync |
| `azure_container_name` | Azure Blob container name |
| `azure_blob_name` | Name of the database file in Azure Blob storage |

## Support

In case of problems or feature requests, please open an issue on GitHub.
