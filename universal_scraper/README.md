# Home Assistant Add-on: Universal Scraper with Telegram

Universal web scraper with Telegram notifications for Home Assistant.

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield] ![Supports i386 Architecture][i386-shield]

## About

This add-on allows you to scrape various websites and receive notifications through Telegram. It supports multiple retailers and can be configured to monitor product availability and price changes.

**✨ Features:**
- 🖥️ **Built-in Web Dashboard** - Accessible directly in Home Assistant sidebar
- 📱 **Telegram Notifications** - Real-time alerts for scraping results  
- ☁️ **Azure Blob Storage Sync** - Automatic database backup and sync
- 🗄️ **Multiple Database Types** - SQLite and MSSQL support
- 🏗️ **Multi-Architecture** - Runs on all Home Assistant platforms

## Installation

The installation of this add-on is straightforward and requires you to add this repository first:

1. Navigate in your Home Assistant frontend to **Settings** → **Add-ons** → **Add-on Store**.
2. Click the **...** button at the top right and select **Repositories**.
3. Add the repository URL: `https://github.com/rtenklooster/homeassistant-universal-scraper-addon`
4. The add-on repository will be updated and the add-on will appear in the add-on store.
5. Install the "Universal Scraper with Telegram" add-on.
6. Configure the add-on and click "Start".
7. **Access the dashboard** by clicking "Open Web UI" or check your Home Assistant sidebar.

## Web Dashboard

Once installed and started, the add-on provides a web dashboard accessible through:

- **Direct access:** Click "Open Web UI" in the add-on page
- **Sidebar integration:** The dashboard appears in your Home Assistant sidebar as "Universal Scraper"

The dashboard allows you to:
- 📊 View current configuration status
- 📥 Download database from Azure Blob Storage  
- 📝 Monitor add-on logs
- ✅ Verify Telegram bot connectivity

## Configuration

Example configuration:

```yaml
telegram_bot_token: "YOUR_BOT_TOKEN"
scrape_interval_minutes: 1
database_type: "sqlite"
admin_token: "YOUR_ADMIN_TOKEN"
azure_blob_url: "https://yourstorageaccount.blob.core.windows.net/yourcontainer/multiscraper.db?sv=2022-11-02&ss=b&srt=o&sp=r&se=2024-12-31T23:59:59Z&st=2023-01-01T00:00:00Z&spr=https&sig=YourSASSignature"
force_db_download: false
db_location: "data"
```

### Configuration Options

| Option | Required | Description | Default | Options |
|--------|----------|-------------|---------|---------|
| `telegram_bot_token` | Yes | Your Telegram Bot Token | `""` | - |
| `scrape_interval_minutes` | Yes | Interval between scrapes in minutes | `1` | - |
| `database_type` | Yes | Database type (sqlite or mssql) | `"sqlite"` | - |
| `admin_token` | Yes | Admin token for API authentication | `""` | - |
| `azure_blob_url` | No | Complete Azure Blob URL with SAS token for database sync | `""` | - |
| `force_db_download` | No | Always download database from Azure, even if it exists | `false` | `true`/`false` |
| `db_location` | No | Where to store the database file | `"data"` | `"data"` or `"config"` |

### Database Storage Location

**New in v1.0.6**: You can now choose where to store your database:

- **`"data"`** (default): Database stored in add-on data directory (`/data/multiscraper.db`)
  - Pros: Isolated from other add-ons
  - Cons: Lost when add-on is uninstalled

- **`"config"`**: Database stored in Home Assistant config directory (`/config/multiscraper.db`)
  - Pros: Persists across add-on reinstalls, accessible to other add-ons
  - Cons: May clutter your config directory

### Force Database Download

**New in v1.0.6**: Set `force_db_download: true` to always download the database from Azure Blob Storage on startup, even if the database file already exists. This is useful for:

- Ensuring you always have the latest data
- Testing database sync functionality
- Recovering from corrupted local databases

### Azure Blob URL Format

Instead of separate connection string, container name, and blob name, you now use a single URL with SAS token:

**Example Azure Blob URL with SAS token:**
```
https://yourstorageaccount.blob.core.windows.net/yourcontainer/multiscraper.db?sv=2022-11-02&ss=b&srt=o&sp=r&se=2024-12-31T23:59:59Z&st=2023-01-01T00:00:00Z&spr=https&sig=YourSASSignature
```

**How to get this URL:**
1. Go to your Azure Storage Account
2. Navigate to your container 
3. Right-click on your database file
4. Select "Generate SAS"
5. Set permissions to "Read" and expiry date
6. Copy the generated "Blob SAS URL"

This is much simpler and more secure than using connection strings!

## Support

For support and troubleshooting, please check the [GitHub repository][github] or open an issue.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[i386-shield]: https://img.shields.io/badge/i386-yes-green.svg
[github]: https://github.com/rtenklooster/homeassistant-universal-scraper-addon
