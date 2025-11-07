import subprocess
import sys
import time

def run_script(script_name, description):
    print(f"Running: {description}")
    
    try:
        result = subprocess.run(
            [sys.executable, script_name],
            check=True,
            capture_output=False
        )
        print(f"{description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"{description} failed with error code {e.returncode}")
        return False

def main():
    print("Starting cron job test sequence...\n")
    
    scripts = [
        ("casino_scraper.py", "Casino Scraper"),
        ("web_parser.py", "Web Parser"),
        ("jackpot_parser.py", "Jackpot Parser"),
        ("calendar_generator.py", "Calendar Generator"),
        ("email_script.py", "Email Script")
    ]
    
    for i, (script, description) in enumerate(scripts, 1):
        success = run_script(script, f"Step {i}: {description}")
        
        if not success:
            print(f"\nStopping execution due to failure in {description}")
            sys.exit(1)
        
        if i < len(scripts):
            print(f"\nWaiting 2 seconds before next script...")
            time.sleep(5)
    
    print("All scripts completed successfully!")

if __name__ == "__main__":
    main()