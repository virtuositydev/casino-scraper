#!/bin/bash
set -e

# Create cron job with FULL environment
echo "Setting up cron job..."

# Capture ALL environment variables from Docker and write them to cron
cat > /etc/cron.d/scraper << EOF
# Set PATH and PYTHONPATH for cron
PATH=/usr/local/bin:/usr/bin:/bin
PYTHONPATH=/usr/local/lib/python3.12/site-packages:/usr/lib/python3/dist-packages
PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
SHELL=/bin/bash

# Environment variables from Docker
$(printenv | grep -v "^_" | grep -v "^HOME" | grep -v "^PWD" | grep -v "^SHLVL" | awk '{print $0}')

EOF

# Append the cron jobs
cat >> /etc/cron.d/scraper << 'EOF'
# Run scraper at 2:14 PM UTC, then process with agent
0 16 * * * cd /app && /usr/bin/python3 casino_scraper.py >> /app/logs/scraper_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 /app/web_parser.py >> /app/logs/processor_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 /app/jackpot_parser.py >> /app/logs/jackpot_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 calendar_generator.py >> /app/logs/calendar_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1 && sleep 5 && /usr/bin/python3 email_script.py >> /app/logs/email_$(date +\%Y\%m\%d_\%H\%M\%S).log 2>&1

# Cleanup old data at 2 AM
0 2 * * * /app/cleanup.sh >> /app/logs/cleanup_$(date +\%Y\%m\%d).log 2>&1
EOF

# Set permissions
chmod 0644 /etc/cron.d/scraper

# Apply cron job
crontab /etc/cron.d/scraper

# Display installed cron jobs
echo "Installed cron jobs:"
crontab -l

# Start cron in foreground
echo "Starting cron..."
cron

# Keep container running
echo "Cron started. Container will keep running..."
tail -f /dev/null