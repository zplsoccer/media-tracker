#!/bin/bash
# TV Show Tracker - Cron Check
# Runs every 2 weeks to check for new seasons, completed shows, or status changes
# Uses Hermes agent to understand context from .md files

VAULT_PATH="/root/obsidian/vault/hermes-data"
TV_DIR="$VAULT_PATH/Media/TV_Shows"
NOTIFY_TARGET="telegram:8599973508"

echo "Starting TV tracker check at $(date)"

# Read all TV show .md files and pass to Hermes agent for analysis
# This script uses hermes-agent to understand the context and send notifications

# Create a summary file that the agent will read
SUMMARY_FILE="/tmp/media_tracker_check_$(date +%s).txt"

echo "=== TV Show Database Check ===" > "$SUMMARY_FILE"
echo "Date: $(date -I)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "=== Shows to Check ===" >> "$SUMMARY_FILE"

# Collect all TV show .md files and their status
for file in "$TV_DIR"/*.md; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    echo "FILE: $filename" >> "$SUMMARY_FILE"
    echo "CONTENT:" >> "$SUMMARY_FILE"
    cat "$file" >> "$SUMMARY_FILE"
    echo "---" >> "$SUMMARY_FILE"
    echo "" >> "$SUMMARY_FILE"
done

echo "TV Tracker check complete. Summary saved to $SUMMARY_FILE"

# Now invoke Hermes agent to read and analyze the file, then notify if needed
# The agent will check for:
# - Shows with status 'watching' that have new season info from TMDB
# - Shows that have been completed but index not updated
# - Shows with upcoming season dates
# The agent uses its AI capabilities to understand the MD content and context

# Send to Telegram with the summary for Hermes agent processing
hermes send --to "$NOTIFY_TARGET" "TV Tracker Check Running (every 2 weeks). Checking $TV_DIR for updates. Please check all .md files and notify if any new seasons started, completed, or are upcoming. Use the media-tracker skill to understand the file format (no bracket filenames, status tracking, seasons)."

echo "Notification sent to Telegram gateway at $(date)"
