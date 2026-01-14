#!/bin/bash
set -e

OUTPUT_DIR="/app/output"
ARCHIVE_DIR="/app/archive"
LOGS_DIR="/app/logs"
FINAL_OUTPUT_DIR="/app/final_output"

echo "Starting cleanup at $(date)"

############################################
# 1️⃣ Ensure archive directory exists
############################################
mkdir -p "$ARCHIVE_DIR"

############################################
# 2️⃣ Archive promo folders older than 7 days
############################################
echo "Archiving promo folders older than 7 days..."
find "$OUTPUT_DIR" -maxdepth 1 -type d -name "promo_*" -mtime +7 \
  -exec mv {} "$ARCHIVE_DIR/" \; 2>/dev/null || true

############################################
# 3️⃣ Compress archived promos older than 30 days
############################################
echo "Compressing archived promo folders older than 30 days..."
find "$ARCHIVE_DIR" -maxdepth 1 -type d -name "promo_*" -mtime +30 | while read -r dir; do
  tar -czf "${dir}.tar.gz" -C "$(dirname "$dir")" "$(basename "$dir")" 2>/dev/null \
    && rm -rf "$dir" \
    && echo "Compressed: $(basename "$dir")"
done

############################################
# 4️⃣ Delete compressed archives older than 90 days
############################################
echo "Deleting compressed archives older than 90 days..."
deleted_archives=$(find "$ARCHIVE_DIR" -name "promo_*.tar.gz" -mtime +90 -delete -print 2>/dev/null | wc -l)
echo "Deleted $deleted_archives archive(s)"

############################################
# 5️⃣ Delete logs older than 30 days
############################################
echo "Deleting logs older than 30 days..."
deleted_logs=$(find "$LOGS_DIR" -name "*.log" -mtime +30 -delete -print 2>/dev/null | wc -l)
echo "Deleted $deleted_logs log file(s)"

############################################
# 6️⃣ FULL RESET: final_output
############################################
echo "Resetting final_output directory..."

if [ -d "$FINAL_OUTPUT_DIR" ]; then
  rm -f "$FINAL_OUTPUT_DIR"/*
  echo "All files removed from final_output"
else
  echo "final_output directory does not exist"
fi

############################################
# 7️⃣ Disk usage summary
############################################
echo ""
echo "Disk usage summary:"
echo "Output:       $(du -sh "$OUTPUT_DIR" 2>/dev/null | cut -f1)"
echo "Archive:      $(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1)"
echo "Logs:         $(du -sh "$LOGS_DIR" 2>/dev/null | cut -f1)"
echo "Final Output: $(du -sh "$FINAL_OUTPUT_DIR" 2>/dev/null | cut -f1)"

echo ""
echo "Cleanup completed at $(date)"
echo "----------------------------------"

exit 0

