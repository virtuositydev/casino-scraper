# Casino Web Scraper - Setup Guide

## Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Git

---

## Setup

### 1. Clone Repository
```bash
git clone https://github.com/virtuositydev/casino-webscraper.git
cd casino-webscraper
```

### 2. Create `.env` File

Create a `.env` file in the project folder:
```bash
nano .env
```

Add this configuration:
```properties
# Timezone
TZ=Asia/Manila

# Scraping Settings
MAX_PAGES_PER_CASINO=None (None for Unlimited)
LOG_LEVEL=INFO

# Ren3 API (Required - get these from Ren3)
REN3_API_URL=api-endpoints
REN3_USER_ID=your-user-id-here
REN3_WORKSPACE_ID=your-workspace-id-here

# Processing
POLL_INTERVAL=15
MAX_RETRIES=3
```

> **Important:** Replace `your-user-id-here` and `your-workspace-id-here` with your actual credentials.

### 3. Start
```bash
# Build and start
docker compose up -d

# Check if running
docker compose ps
```

### 4. Test
```bash
# Run scraper once
docker compose exec casino-scraper python3 casino_scraper.py

# Check output
ls output/
```

---

## Usage

### Automatic Running
Scraper runs daily at **8:00 AM** automatically.

### Manual Run
```bash
docker compose exec casino-scraper python3 casino_scraper.py
```

### View Logs
```bash
docker compose logs -f casino-scraper
```

### View Data
```bash
# List scraped data
ls output/promo_*/

# View jackpots
cat output/promo_*/jackpots.json

# Web dashboard
# http://your-server-ip:8081
```

---

## Common Commands
```bash
# Start
docker compose start

# Stop
docker compose stop

# Restart
docker compose restart

# Update code
git pull
docker compose restart

# View logs
docker compose logs -f casino-scraper

# Manual cleanup
docker compose exec casino-scraper /app/cleanup.sh
```

---

## Automatic Cleanup

- Folders older than 7 days → archived
- Archives older than 30 days → compressed
- Compressed archives older than 90 days → deleted
- Logs older than 30 days → deleted

---

## Troubleshooting

**Container won't start?**
```bash
docker compose logs casino-scraper
```

**No files in output?**
```bash
# Check if .env exists
cat .env

# Run manually to see errors
docker compose exec casino-scraper python3 casino_scraper.py
```

**Dashboard not working?**
```bash
docker compose logs scraper-dashboard
```

---

## File Locations
```
output/              # Scraped data here
logs/                # Log files here
archive/             # Old data archived here
.env                 # Your config file (you create this)
```

---

## Support

Check logs first: `docker compose logs -f casino-scraper`