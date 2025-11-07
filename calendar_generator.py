import pandas as pd
from datetime import datetime, timedelta
from collections import defaultdict
from pathlib import Path
import sys

# Set input file path
input_file = Path('/app/final_output/web_promo.csv')

if not input_file.exists():
    print(f"ERROR: File not found: {input_file}")
    sys.exit(1)

print(f"Using CSV file: {input_file}")

# Read the CSV file
df = pd.read_csv(input_file)

# Function to find column name flexibly
def find_column(df, possible_names):
    """Find column name from a list of possible variations"""
    for name in possible_names:
        if name in df.columns:
            return name
    return None

# Find the correct column names (case-insensitive and with/without underscores)
start_date_variations = ['Start_Date', 'Start Date', 'start_date', 'start date', 'StartDate', 'startdate']
end_date_variations = ['End_Date', 'End Date', 'end_date', 'end date', 'EndDate', 'enddate']
resort_variations = ['Resort', 'resort', 'RESORT']
deals_variations = ['Deals', 'deals', 'DEALS', 'Deal', 'deal']
category_variations = ['Deals Type', 'Deals_Type', 'deals type', 'deals_type', 'DealsType', 'Category', 'category', 'CATEGORY', 'Type', 'type']

start_col = find_column(df, start_date_variations)
end_col = find_column(df, end_date_variations)
resort_col = find_column(df, resort_variations)
deals_col = find_column(df, deals_variations)
category_col = find_column(df, category_variations)

# Check if required columns exist
if not start_col:
    print(f"ERROR: Could not find Start Date column. Available columns: {list(df.columns)}")
    sys.exit(1)
if not end_col:
    print(f"ERROR: Could not find End Date column. Available columns: {list(df.columns)}")
    sys.exit(1)
if not resort_col:
    print(f"ERROR: Could not find Resort column. Available columns: {list(df.columns)}")
    sys.exit(1)
if not deals_col:
    print(f"ERROR: Could not find Deals column. Available columns: {list(df.columns)}")
    sys.exit(1)

print(f"Found columns: Start='{start_col}', End='{end_col}', Resort='{resort_col}', Deals='{deals_col}'")
if category_col:
    print(f"Category column found: '{category_col}'")
else:
    print("WARNING: Category column not found. All items will be categorized as 'Non Gaming'")

# Convert date columns to datetime, handling errors
df[start_col] = pd.to_datetime(df[start_col], errors='coerce')
df[end_col] = pd.to_datetime(df[end_col], errors='coerce')

# For 'Ongoing' or invalid end dates, set to a far future date (1 year from start)
df[end_col] = df.apply(
    lambda row: row[start_col] + timedelta(days=365) if pd.isna(row[end_col]) else row[end_col],
    axis=1
)

# Remove rows where Start_Date is invalid
df = df.dropna(subset=[start_col])

# Calculate date range: current week + next week
today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
# Find the start of current week (Monday)
current_week_start = today - timedelta(days=today.weekday())
# End of next week (Sunday of next week)
next_week_end = current_week_start + timedelta(days=13)  # 2 weeks - 1 day

print(f"\nFiltering dates from {current_week_start.strftime('%d-%m-%Y')} to {next_week_end.strftime('%d-%m-%Y')}")
print(f"Current week: {current_week_start.strftime('%d-%m-%Y')} to {(current_week_start + timedelta(days=6)).strftime('%d-%m-%Y')}")
print(f"Next week: {(current_week_start + timedelta(days=7)).strftime('%d-%m-%Y')} to {next_week_end.strftime('%d-%m-%Y')}")

# Dictionary to hold all events by date and category
# Structure: {date: {'Gaming': [...], 'Non Gaming': [...]}}
events_by_date = defaultdict(lambda: {'Gaming': [], 'Non Gaming': []})

# Process each row
for idx, row in df.iterrows():
    resort = row[resort_col]
    deal = row[deals_col]
    start_date = row[start_col]
    end_date = row[end_col]
    
    # Determine category based on Deals Type column
    if category_col and pd.notna(row[category_col]):
        category_value = str(row[category_col]).strip()
        # Check if it starts with "Gaming" (case-insensitive)
        if category_value.lower().startswith('gaming'):
            category = 'Gaming'
        else:
            # All Non-Gaming variants go to Non Gaming
            category = 'Non Gaming'
    else:
        category = 'Non Gaming'
    
    # Create event string
    event_text = f"{resort} - {deal}"
    
    # Add event to all dates in the range (but only within our 2-week window)
    current_date = max(start_date, current_week_start)  # Start from current week start or promo start
    end_limit = min(end_date, next_week_end)  # End at next week end or promo end
    
    # Only process if the promotion overlaps with our date range
    if current_date <= end_limit:
        while current_date <= end_limit:
            date_key = current_date.strftime('%d-%m-%Y')
            events_by_date[date_key][category].append(event_text)
            current_date += timedelta(days=1)

# Sort dates
sorted_dates = sorted(events_by_date.keys(), key=lambda x: datetime.strptime(x, '%d-%m-%Y'))

# Generate the calendar text
output_lines = []
for date_str in sorted_dates:
    # Parse date to get weekday
    date_obj = datetime.strptime(date_str, '%d-%m-%Y')
    weekday = date_obj.strftime('%A')
    
    # Add date header with weekday
    date_header = f"{date_str} ({weekday})"
    output_lines.append(date_header)
    output_lines.append("=" * len(date_header))
    
    # Process Gaming category
    gaming_events = list(set(events_by_date[date_str]['Gaming']))
    if gaming_events:
        gaming_events.sort()
        output_lines.append("Gaming")
        for event in gaming_events:
            output_lines.append(f"- {event}")
        output_lines.append("")  # Empty line between categories
    
    # Process Non Gaming category
    non_gaming_events = list(set(events_by_date[date_str]['Non Gaming']))
    if non_gaming_events:
        non_gaming_events.sort()
        output_lines.append("Non Gaming")
        for event in non_gaming_events:
            output_lines.append(f"- {event}")
    
    output_lines.append("")  # Empty line between dates

# Create filename with date range
start_date_str = current_week_start.strftime('%d-%m-%Y')
end_date_str = next_week_end.strftime('%d-%m-%Y')
output_filename = f"marketing_calendar_website_{start_date_str}_to_{end_date_str}.txt"
output_file = Path('/app/final_output') / output_filename

# Write to file (save in /app/final_output)
with open(output_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(output_lines))

print(f"\n{'='*60}")
print(f"Calendar generated successfully!")
print(f"Output file: {output_file}")
print(f"Total dates with events: {len(sorted_dates)}")
print(f"{'='*60}")
print(f"\nFirst few entries:")
print('\n'.join(output_lines[:40]))