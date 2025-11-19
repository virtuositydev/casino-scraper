#!/bin/bash

# Cleanup script for old data
OUTPUT_DIR="/app/output"
ARCHIVE_DIR="/app/archive"
LOGS_DIR="/app/logs"
FINAL_OUTPUT_DIR="/app/final_output"

echo "Starting cleanup at $(date)"

# Create archive directory if it doesn't exist
mkdir -p "$ARCHIVE_DIR"

# Move promo folders older than 7 days to archive
echo "Moving folders older than 7 days to archive..."
find "$OUTPUT_DIR" -maxdepth 1 -type d -name "promo_*" -mtime +7 -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null

# Compress archives older than 30 days
echo "Compressing archives older than 30 days..."
find "$ARCHIVE_DIR" -maxdepth 1 -type d -name "promo_*" -mtime +30 | while read -r dir; do
    if [ -d "$dir" ]; then
        tar -czf "${dir}.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null
        if [ $? -eq 0 ]; then
            rm -rf "$dir"
            echo "Compressed: $(basename "$dir")"
        else
            echo "Failed to compress: $(basename "$dir")"
        fi
    fi
done

# Delete compressed archives older than 90 days
echo "Deleting archives older than 90 days..."
deleted_count=$(find "$ARCHIVE_DIR" -name "promo_*.tar.gz" -mtime +90 -delete -print | wc -l)
echo "Deleted $deleted_count archive(s)"

# Delete logs older than 30 days
echo "Deleting logs older than 30 days..."
deleted_logs=$(find "$LOGS_DIR" -name "*.log" -mtime +30 -delete -print 2>/dev/null | wc -l)
echo "Deleted $deleted_logs log file(s)"

# Clean final_output directory (delete files not from today)
echo "Cleaning final_output directory..."
if [ -d "$FINAL_OUTPUT_DIR" ]; then
    deleted_final=$(find "$FINAL_OUTPUT_DIR" -type f -mtime +0 -delete -print 2>/dev/null | wc -l)
    echo "Deleted $deleted_final file(s) from final_output"
else
    echo "final_output directory does not exist"
fi

# Print disk usage summary
echo ""
echo "Disk usage summary:"
echo "Output: $(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)"
echo "Archive: $(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1)"
echo "Logs: $(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1)"
echo "Final Output: $(du -sh "$FINAL_OUTPUT_DIR" 2>/dev/null | cut -f1)"

echo ""
echo "Cleanup completed at $(date)"
echo "---"

# Exit with success
exit 0