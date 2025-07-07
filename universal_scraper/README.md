# Home Assistant Add-on: Universal Scraper with Telegram

Universal web scraper with Telegram notifications for Home Assistant.

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

## About

This add-on allows you to scrape various websites and receive notifications through Telegram. It supports multiple retailers and can be configured to monitor product availability and price changes.

## Installation

The installation of this add-on is straightforward and requires you to add this repository first:

1. Navigate in your Home Assistant frontend to **Settings** → **Add-ons** → **Add-on Store**.
2. Click the **...** button at the top right and select **Repositories**.
3. Add the repository URL: `https://github.com/rtenklooster/homeassistant-universal-scraper-addon`
4. The add-on repository will be updated and the add-on will appear in the add-on store.
5. Install the "Universal Scraper with Telegram" add-on.
6. Configure the add-on and click "Start".

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

### Configuration Options

| Option | Required | Description | Default |
|--------|----------|-------------|---------|
| `telegram_bot_token` | Yes | Your Telegram Bot Token | `""` |
| `scrape_interval_minutes` | Yes | Interval between scrapes in minutes | `1` |
| `database_type` | Yes | Database type (sqlite or mssql) | `"sqlite"` |
| `web_url` | Yes | URL where the web interface will be available | `"http://homeassistant:3000"` |
| `admin_token` | Yes | Admin token for API authentication | `""` |
| `azure_storage_connection_string` | No | Azure Storage connection string for database sync | `""` |
| `azure_container_name` | No | Azure Blob container name | `""` |
| `azure_blob_name` | No | Name of the database file in Azure Blob storage | `"multiscraper.db"` |

## Support

For support and troubleshooting, please check the [GitHub repository][github] or open an issue.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[github]: https://github.com/rtenklooster/homeassistant-universal-scraper-addon
