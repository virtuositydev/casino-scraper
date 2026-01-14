#!/bin/bash
set -e

echo "Setting up cron job..."

# --------------------------------------------------
# Write cron file (env + jobs)
# --------------------------------------------------
cat > /etc/cron.d/scraper << EOF
# Set PATH and PYTHONPATH for cron
PATH=/usr/local/bin:/usr/bin:/bin
PYTHONPATH=/usr/local/lib/python3.12/site-packages:/usr/lib/python3/dist-packages
PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
SHELL=/bin/bash

# Environment variables from Docker
$(printenv | grep -v "^_" | grep -v "^HOME" | grep -v "^PWD" | grep -v "^SHLVL")

# ==================================================
# Cleanup – 7:50 AM Malaysia time (23:50 UTC)
# ==================================================
50 23 * * * /app/cleanup.sh >> /app/logs/cleanup_\$(date +\%Y\%m\%d_\%H\%M).log 2>&1

# ==================================================
# Main scraper run – 8:00 AM Malaysia time (00:00 UTC)
# ==================================================
0 0 * * * cd /app && /usr/bin/python3 casino_scraper.py >> /app/logs/scraper_\$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 web_parser.py >> /app/logs/processor_\$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 jackpot_parser.py >> /app/logs/jackpot_\$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 calendar_generator.py >> /app/logs/calendar_\$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 email_script.py >> /app/logs/email_\$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1
EOF

# --------------------------------------------------
# Permissions required by cron
# --------------------------------------------------
chmod 0644 /etc/cron.d/scraper

# --------------------------------------------------
# Install as USER crontab (same as original setup)
# --------------------------------------------------
crontab /etc/cron.d/scraper

echo "Installed cron jobs:"
crontab -l

# --------------------------------------------------
# Start cron
# --------------------------------------------------
echo "Starting cron..."
cron

# --------------------------------------------------
# Keep container alive
# --------------------------------------------------
echo "Cron started. Container will keep running..."
tail -f /dev/null
