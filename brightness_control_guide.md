# Time-Based Brightness Control for Ubuntu 22.04: A Complete Guide

Managing screen brightness automatically based on the time of day can significantly improve your computing experience and reduce eye strain. In this guide, we'll create a script that automatically adjusts your screen brightness throughout the day, simulating natural light patterns.

## What We'll Build

Our script will:
- **Morning (7:00-9:00 AM)**: Gradually increase brightness from 2% to 100%
- **Day (9:00 AM-5:00 PM)**: Maintain maximum brightness (100%)
- **Evening (5:00-11:59 PM)**: Gradually decrease brightness from 100% to 2%
- **Night (12:00-6:59 AM)**: Maintain minimum brightness (2%)

## Prerequisites

- Ubuntu 22.04 (should work on other Ubuntu versions too)
- X11 Server
- Terminal access with sudo privileges
- A laptop or monitor that supports brightness control

## Step 1: Install brightnessctl

First, we need to install `brightnessctl`, a utility that allows us to control screen brightness from the command line.

```bash
sudo apt update
sudo apt install brightnessctl
```

Verify the installation by checking available brightness controls:

```bash
brightnessctl --list
```

You should see output similar to:
```
Available devices:
Device 'intel_backlight' of class 'backlight':
	Current brightness: 850 (80%)
	Max brightness: 1060
```

## Step 2: Create the Brightness Control Script

Create a new script file:

```bash
nano ~/TimeBasedBrightControl.sh
```

Add the following content:

```bash
#!/bin/bash

# Get current hour and minutes (remove leading zeros)
current_hour=$(date +%-H)
current_minute=$(date +%-M)

# Add debug output
echo "Current time: $current_hour:$current_minute"

# Function to calculate brightness
calculate_brightness() {
    # If time is between 17:00 and 23:59
    if [ $current_hour -ge 17 ] && [ $current_hour -lt 24 ]; then
        # Total minutes from 17:00 to 24:00
        local total_minutes_decrease=420  # 7 hours * 60 minutes
        
        # Current minutes since 17:00
        local minutes_since_17=$(( (current_hour - 17) * 60 + current_minute ))
        
        # Linear interpolation from 100% to 2%
        # Formula: 100 - (minutes_since_17 / total_minutes_decrease) * (100 - 2)
        local brightness=$(( 100 - (minutes_since_17 * 98 / total_minutes_decrease) ))
        
        # Output debug information to stderr
        echo "Time $current_hour:$current_minute. Decreasing brightness." >&2
        echo "Minutes after 17:00: $minutes_since_17" >&2
        echo "Calculated brightness: $brightness%" >&2
        
        # Limit minimum brightness to 2%
        if [ $brightness -lt 2 ]; then
            brightness=2
        fi
        
        # Return only numeric value
        echo $brightness
    # If time is between 00:00 and 06:59
    elif [ $current_hour -lt 7 ]; then
        echo "Time $current_hour:$current_minute. Minimum brightness." >&2
        echo 2
    # If time is between 07:00 and 08:59
    elif [ $current_hour -ge 7 ] && [ $current_hour -lt 9 ]; then
        # Total minutes from 07:00 to 09:00
        local total_minutes_increase=120 # 2 hours * 60 minutes
        
        # Current minutes since 07:00
        local minutes_since_7=$(( (current_hour - 7) * 60 + current_minute ))
        
        # Linear interpolation from 2% to 100%
        # Formula: 2 + (minutes_since_7 / total_minutes_increase) * (100 - 2)
        local brightness=$(( 2 + (minutes_since_7 * 98 / total_minutes_increase) ))
        
        # Output debug information to stderr
        echo "Time $current_hour:$current_minute. Increasing brightness." >&2
        echo "Minutes after 07:00: $minutes_since_7" >&2
        echo "Calculated brightness: $brightness%" >&2
        
        # Limit maximum brightness to 100% (just in case)
        if [ $brightness -gt 100 ]; then
            brightness=100
        fi
        
        # Return only numeric value
        echo $brightness
    # Otherwise (time between 09:00 and 16:59)
    else
        echo "Time $current_hour:$current_minute. Maximum brightness." >&2
        echo 100
    fi
}

# Get calculated brightness (only number)
brightness=$(calculate_brightness)

# Add debug output
echo "Final brightness: $brightness"

# If brightness is defined, set it
if [ ! -z "$brightness" ]; then
    echo "Setting brightness: $brightness%"
    sudo brightnessctl set "$brightness%"
else
    echo "Brightness not defined (error in calculations)"
fi
```

## Step 3: Make the Script Executable

```bash
chmod +x ~/TimeBasedBrightControl.sh
```

## Step 4: Test the Script

Run the script manually to ensure it works:

```bash
~/TimeBasedBrightControl.sh
```

You should see output like:
```
Current time: 14:30
Time 14:30. Maximum brightness.
Final brightness: 100
Setting brightness: 100%
```

## Step 5: Handle Sudo Requirements

Since we'll be running the script through `sudo crontab -e` (root crontab), the script will automatically have the necessary privileges to control brightness.

## Step 6: Set Up Automation with Cron

⚠️ **IMPORTANT**: You must use `sudo crontab -e` instead of regular `crontab -e` for the brightness control to work properly. Regular user cron jobs don't have the necessary permissions to control system brightness.

Open the root crontab:

```bash
sudo crontab -e
```

Add the following line to run the script every 5 minutes:

```bash
*/5 * * * * /bin/bash "/home/username/TimeBasedBrightControl.sh"
```

Replace `username` with your actual username. This will:
- Run the script every 5 minutes using `/bin/bash` explicitly
- Execute with root privileges (necessary for brightness control)
- Log output to `~/brightness.log`
- Capture both standard output and errors

**Example with actual path:**
```bash
*/5 * * * * /bin/bash "/home/fedor/TimeBasedBrightControl.sh"
```

## Step 7: Monitor the Script

Check if the cron job is working:

```bash
tail -f ~/brightness.log
```

You should see entries being added every 5 minutes.

## Understanding the Brightness Calculation

The script uses linear interpolation to smoothly transition brightness:

### Evening Transition (17:00-23:59)
- **Duration**: 7 hours (420 minutes)
- **Range**: 100% → 2%
- **Formula**: `100 - (minutes_since_17 * 98 / 420)`

### Morning Transition (07:00-08:59)
- **Duration**: 2 hours (120 minutes)
- **Range**: 2% → 100%
- **Formula**: `2 + (minutes_since_7 * 98 / 120)`

## Customization Options

### Adjust Time Ranges

To change the time periods, modify these conditions in the script:

```bash
# Change evening start time (currently 17:00)
if [ $current_hour -ge 17 ] && [ $current_hour -lt 24 ]; then

# Change morning start time (currently 07:00)
elif [ $current_hour -ge 7 ] && [ $current_hour -lt 9 ]; then

# Change night end time (currently 06:59)
elif [ $current_hour -lt 7 ]; then
```

### Adjust Brightness Levels

To change minimum/maximum brightness levels:

```bash
# Change minimum brightness (currently 2%)
echo 2

# In the interpolation formulas, change the range:
# Currently: 98 (which is 100-2)
# For 5%-95% range, use: 90 (which is 95-5)
local brightness=$(( 5 + (minutes_since_7 * 90 / total_minutes_increase) ))
```

### Change Update Frequency

Modify the cron schedule:

```bash
# Every minute
* * * * * /home/username/TimeBasedBrightControl.sh

# Every 10 minutes
*/10 * * * * /home/username/TimeBasedBrightControl.sh

# Every 30 minutes
*/30 * * * * /home/username/TimeBasedBrightControl.sh
```

## Troubleshooting

### Script Not Running
1. Check if cron is running: `sudo systemctl status cron`
2. Verify root crontab syntax: `sudo crontab -l`
3. Check permissions: `ls -la ~/TimeBasedBrightControl.sh`

### Brightness Not Changing
1. Verify brightnessctl works: `sudo brightnessctl set 50%`
2. Check if script runs manually: `sudo /bin/bash "/home/username/TimeBasedBrightControl.sh"`
3. Review log file: `cat ~/brightness.log`

### Permission Issues
If you get permission errors:

```bash
# Make sure the script has proper permissions
chmod +x ~/TimeBasedBrightControl.sh

# Check if running with sudo crontab
sudo crontab -l | grep TimeBasedBrightControl
```

## Conclusion

This time-based brightness control system provides a smooth, automated way to manage screen brightness throughout the day. The linear interpolation ensures gradual transitions that are easy on the eyes, while the cron-based automation means you'll never have to manually adjust brightness again.

The script is highly customizable, allowing you to adjust time ranges, brightness levels, and update frequencies to match your specific needs and schedule.

## Ready Script

You can find the complete working script in this repository: [TimeBasedBrightControl](https://github.com/pefbrute/TimeBasedBrightControl)

---

*Found this guide helpful? Feel free to customize the script for your needs and share your improvements in the comments below!* 