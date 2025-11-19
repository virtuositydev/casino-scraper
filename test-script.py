import subprocess
import sys
import time
from datetime import datetime
import os

def run_script(script_name, description, log_prefix):
    print(f"Running: {description}")
    
    # Create logs directory if it doesn't exist
    os.makedirs("/app/logs", exist_ok=True)
    
    # Generate timestamp for log filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = f"/app/logs/{log_prefix}_{timestamp}.log"
    
    try:
        with open(log_file, "w") as f:
            result = subprocess.run(
                [sys.executable, script_name],
                stdout=f,
                stderr=subprocess.STDOUT,
                check=True
            )
        print(f"{description} completed successfully. Log: {log_file}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{description} failed with error code {e.returncode}. Log: {log_file}")
        return False

def main():
    print("Starting cron job test sequence...\n")
    
    scripts = [
        ("casino_scraper.py", "Casino Scraper", "scraper"),
        ("web_parser.py", "Web Parser", "processor"),
        ("jackpot_parser.py", "Jackpot Parser", "jackpot"),
        ("calendar_generator.py", "Calendar Generator", "calendar"),
        ("email_script.py", "Email Script", "email")
    ]
    
    for i, (script, description, log_prefix) in enumerate(scripts, 1):
        success = run_script(script, f"Step {i}: {description}", log_prefix)
        
        if not success:
            print(f"\nStopping execution due to failure in {description}")
            sys.exit(1)
        
        if i < len(scripts):
            print(f"\nWaiting 5 seconds before next script...")
            time.sleep(5)
    
    print("\nAll scripts completed successfully!")

if __name__ == "__main__":
    main()