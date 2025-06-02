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