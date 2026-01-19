#!/bin/bash

# ref. https://qiita.com/Rollphes/items/e6edb2822687f8472e05
# ref. https://gist.github.com/Rollphes/61e884766c0521c32982eee642360614

set -euo pipefail

# Environment detection
detect_os() {
    case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*) echo "linux" ;;
    msys* | mingw* | cygwin*) echo "windows" ;;
    *) echo "unknown" ;;
    esac
}

OS_TYPE=$(detect_os)

# Cross-platform math calculation
safe_math() {
    local expression=$1

    if command -v bc &>/dev/null; then
        echo "$expression" | bc -l 2>/dev/null || echo "0"
    elif command -v powershell.exe &>/dev/null; then
        powershell.exe -Command "($expression)" 2>/dev/null || echo "0"
    elif command -v awk &>/dev/null; then
        echo "" | awk "BEGIN {print $expression}" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# Cross-platform number formatting
format_number_with_commas() {
    local number=$1

    if command -v numfmt &>/dev/null; then
        numfmt --grouping "$number" 2>/dev/null || echo "$number"
    elif command -v powershell.exe &>/dev/null; then
        powershell.exe -Command "[int]$number | ForEach-Object { '{0:N0}' -f \$_ }" 2>/dev/null || echo "$number"
    elif printf "%'d" "$number" &>/dev/null; then
        printf "%'d" "$number"
    elif command -v sed &>/dev/null; then
        echo "$number" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
    else
        echo "$number"
    fi
}

# Cross-platform time calculation
calculate_reset_time() {
    local minutes=$1

    case "$OS_TYPE" in
    "macos")
        date -v +"$minutes"M "+%H:%M" 2>/dev/null || echo "N/A"
        ;;
    "linux")
        date -d "+$minutes minutes" "+%H:%M" 2>/dev/null || echo "N/A"
        ;;
    "windows")
        powershell.exe -Command "(Get-Date).AddMinutes($minutes).ToString('HH:mm')" 2>/dev/null || echo "N/A"
        ;;
    *)
        echo "N/A"
        ;;
    esac
}

# Cross-platform token limit extraction
extract_token_limit() {
    local ccusage_output
    ccusage_output=$(npx ccusage blocks 2>&1)

    if command -v grep &>/dev/null; then
        echo "$ccusage_output" | grep -o "assuming [0-9,]* token limit" | grep -o "[0-9,]*" | tr -d ','
    elif command -v powershell.exe &>/dev/null; then
        echo "$ccusage_output" | powershell.exe -Command '\$input | Select-String "assuming ([0-9,]*) token limit" | ForEach-Object { \$_.Matches[0].Groups[1].Value -replace ",","" }'
    else
        echo "$ccusage_output" | sed -n 's/.*assuming \([0-9,]*\) token limit.*/\1/p' | tr -d ','
    fi
}

# Dependency check
check_dependencies() {
    local missing_deps=()

    if ! command -v npx &>/dev/null; then
        missing_deps+=("npx (Node.js)")
    fi

    if ! command -v jq &>/dev/null; then
        missing_deps+=("jq")
    fi

    if ! command -v bc &>/dev/null && ! command -v powershell.exe &>/dev/null && ! command -v awk &>/dev/null; then
        missing_deps+=("bc or PowerShell or awk")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing dependencies: ${missing_deps[*]}"
        echo "Please install the required tools for your platform."
        exit 1
    fi
}

# $1: remaining minutes
# Output: formatted remaining time (e.g., "1h 3m left") or "N/A"
format_remaining_time() {
    local minutes=$1
    if [ "$minutes" != "null" ]; then
        local h=$((minutes / 60))
        local m=$((minutes % 60))
        printf "%dh %dm left" "$h" "$m"
    else
        echo "N/A"
    fi
}

# $1: UTC time string
# $2: desired output format (e.g., "%H:%M")
# Output: formatted local time or "N/A"
format_time_local() {
    local utc_time=$1
    local format_str=$2

    if [ "$utc_time" != "null" ] && [ -n "$utc_time" ]; then
        case "$OS_TYPE" in
        "macos")
            date -j -f "%Y-%m-%dT%H:%M:%S" "${utc_time%.*}" "+$format_str" 2>/dev/null || echo "N/A"
            ;;
        "linux")
            date -d "$utc_time" "+$format_str" 2>/dev/null || echo "N/A"
            ;;
        "windows")
            powershell.exe -Command "Get-Date '$utc_time' -Format '$format_str'" 2>/dev/null || echo "N/A"
            ;;
        *)
            echo "N/A"
            ;;
        esac
    else
        echo "N/A"
    fi
}

# Check dependencies first
check_dependencies

# Read Claude input from stdin first
claude_input=$(cat)

ccusage=$(npx ccusage blocks --json 2>/dev/null)
if [ -z "$ccusage" ]; then
    echo "Error: Failed to fetch data from 'npx ccusage blocks --json'."
    echo "Please ensure ccusage is installed and functioning correctly."
    exit 1
fi

# Get the assumed token limit from ccusage text output
assumed_limit=$(extract_token_limit)
if [ -z "$assumed_limit" ]; then
    assumed_limit="null"
fi

active_block=$(echo "$ccusage" | jq '.blocks[] | select(.isActive == true)')
if [ -z "$active_block" ]; then
    echo "No active usage block found."
    exit 0
fi

# Now Model
model_name=$(echo "$claude_input" | jq -r '.model.display_name') # e.g: Sonnet 4

# Information
id=$(echo "$active_block" | jq -r '.id')                         # e.g: 2025-09-21T00:00:00.000Z
start_time=$(echo "$active_block" | jq -r '.startTime')          # e.g: 2025-09-21T00:00:00.000Z
end_time=$(echo "$active_block" | jq -r '.endTime')              # e.g: 2025-09-21T05:00:00.000Z
actual_end_time=$(echo "$active_block" | jq -r '.actualEndTime') # e.g: 2025-09-21T03:33:17.285Z
entries=$(echo "$active_block" | jq -r '.entries')               # e.g: 166

# Used tokens
input_tokens=$(echo "$active_block" | jq -r '.tokenCounts.inputTokens')                       # e.g: 503
output_tokens=$(echo "$active_block" | jq -r '.tokenCounts.outputTokens')                     # e.g: 22814
cache_creation_tokens=$(echo "$active_block" | jq -r '.tokenCounts.cacheCreationInputTokens') # e.g: 404511
cache_read_tokens=$(echo "$active_block" | jq -r '.tokenCounts.cacheReadInputTokens')         # e.g: 10004316
total_tokens=$(echo "$active_block" | jq -r '.totalTokens')                                   # e.g: 10432144

# Now Cost (USD)
cost=$(echo "$active_block" | jq -r '.costUSD') # e.g: 8.285881650000004

# Burn rate
tokens_per_minute=$(echo "$active_block" | jq -r '.burnRate.tokensPerMinute')                           # e.g: 54098.75843023459
tokens_per_minute_for_indicator=$(echo "$active_block" | jq -r '.burnRate.tokensPerMinuteForIndicator') # e.g: 120.91673104951197
cost_per_hour=$(echo "$active_block" | jq -r '.burnRate.costPerHour')                                   # e.g: 2.5781234026190427

# Projection
projected_tokens=$(echo "$active_block" | jq -r '.projection.totalTokens')       # e.g: 13845592
projected_cost=$(echo "$active_block" | jq -r '.projection.totalCost')           # e.g: 11
remaining_minutes=$(echo "$active_block" | jq -r '.projection.remainingMinutes') # e.g: 63

# Calculate usage percentage using assumed limit
if [ "$assumed_limit" != "null" ] && [ "$assumed_limit" != "0" ]; then
    usage_percent=$(safe_math "$total_tokens / $assumed_limit * 100")
    usage_percent=$(printf "%.1f" "$usage_percent")
else
    usage_percent="N/A"
fi

# Reset Time
remaining_time_str=$(format_remaining_time "$remaining_minutes") # e.g: 1h 3m left

# Calculate reset time (current time + remaining minutes)
if [ "$remaining_minutes" != "null" ]; then
    reset_time=$(calculate_reset_time "$remaining_minutes")
    if [ "$reset_time" != "N/A" ]; then
        reset_time_str="$remaining_time_str ($reset_time)"
    else
        reset_time_str="$remaining_time_str"
    fi
else
    reset_time_str="$remaining_time_str"
fi

# Output formatting
model_str=$(printf "🤖 %s" "$model_name")
cost_str=$(printf "💵 \$%.2f" "$cost")

# Token with limit
if [ "$assumed_limit" != "null" ] && [ "$assumed_limit" != "0" ]; then
    token_str=$(printf "🔢 %s / %s (assuming)" "$(format_number_with_commas "$total_tokens")" "$(format_number_with_commas "$assumed_limit")")
else
    token_str=$(printf "🔢 %s" "$(format_number_with_commas "$total_tokens")")
fi

# Usage percentage with color indicator
if [ "$usage_percent" != "N/A" ]; then
    usage_float=$(printf "%.0f" "$usage_percent" 2>/dev/null || echo "0")
    if [ "$usage_float" -le 25 ]; then
        usage_indicator="🟢"
    elif [ "$usage_float" -le 50 ]; then
        usage_indicator="🟡"
    elif [ "$usage_float" -le 75 ]; then
        usage_indicator="🟠"
    else
        usage_indicator="🔴"
    fi
    using_str=$(printf "%s %s%%" "$usage_indicator" "$usage_percent")
else
    using_str="📊 N/A"
fi

reset_str=$(printf "⏱️  %s" "$reset_time_str")

# Burn rate indicator with percentage
if [ "$tokens_per_minute_for_indicator" != "null" ]; then
    burn_percentage=$(printf "%.0f" "$tokens_per_minute_for_indicator" 2>/dev/null || echo "0")

    if [ "$burn_percentage" -gt 100 ]; then
        burn_str=$(printf "🔥\033[31m %s%%\033[90m" "$burn_percentage")
    else
        burn_str=$(printf "🔥 %s%%" "$burn_percentage")
    fi
else
    burn_str="🔥 N/A"
fi

# Output the status line
printf "\033[90m%s │ %s │ %s │ %s │ %s │ %s" "$model_str" "$cost_str" "$token_str" "$using_str" "$burn_str" "$reset_str"
