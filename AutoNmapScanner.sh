#!/bin/bash

# Usage chart showing all available scan types
usage() 
{
    echo "Usage: $0 <target> <scan_type1> [<scan_type2> ...]"
    echo "Available scan types:"
    echo "  hosts         Host Discovery scan"
    echo "  basic         Basic scan" 
    echo "  udp           UDP scan" 
    echo "  full          Full scan"
    echo "  vuln          Vulnerability scan"
    echo "  discovery     Discovery scan"
    echo "  all           All available scan types"
    exit 1
}


# Define the available scan types and their options
# To add more scan types the following template can be used
# ["<scan name>"]="<nmap arguements>"
# Make sure to update the usage chart at the top
declare -A SCAN_TYPES=(
    ["hosts"]="-sn -PR -T4"
    ["basic"]="-p- -T4"
    ["full"]="-sV -A -O -T4 -p- -Pn -T4"
    ["udp"]="-sU --max-retries 1 --min-rate 5000 -T4"
    ["vuln"]="--script vuln -p- -T4"
    ["discovery"]="-sn -sV --script discovery -T4"
    ["all"]=""
)

# Prints header
print_header() 
{
    local scan_type=$1
    local len=${#scan_type}
    local terminal_width=$(tput cols)
    local margin=$(( (terminal_width - len) / 2 ))
    local line=$(printf  "%*s" "$terminal_width" | tr ' ' -)
    printf "\n%s\n%*s%s\n%s\n\n" "$line" "$margin" "" "BEGINNING ${scan_type^^}" "$line"
}

# Checks to make sure there are at least 2 arguments provided. If fewer than 2 are provided, prints usage and exits.
if [ $# -lt 2 ]; then
    usage
fi

# Set the target IP address or range of addresses to scan
TARGET="$1"
shift

# Convert the scan type arguments provided by the user to lowercase
scan_types=()
for scan_type in "$@"; do
    scan_types+=("${scan_type,,}")
done

# Checks to make sure all scan types are valid
for scan_type in "${scan_types[@]}"; do
    if [[ ! ${SCAN_TYPES[$scan_type]} && $scan_type != "all" ]]; then
        echo "Invalid scan type: $scan_type. Please select a valid scan type."
        usage
    fi
done

# If the all scan type is used, set the scan_types list to all available scan types listed in the SCAN_TYPES list
# If the all scan type is not used, set the scan_types list to all stated scans by the user
if [[ " ${scan_types[@]} " =~ " all " ]]; then
    scan_types=()
    for key in "${!SCAN_TYPES[@]}"; do
        if [[ "$key" != "all" ]]; then
            scan_types+=("$key")
        fi
    done
fi

# Gathers IP addresses marked as up and performs selected scan types against each IP address
IP_LIST=$(nmap -n -sn "$TARGET" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
for IP in $IP_LIST; do
    for scan_type in "${scan_types[@]}"; do
        print_header "$scan_type"
        echo "Running $scan_type scan for $IP"
        OUTPUT_DIR="NmapScans/$IP"
        mkdir -p "$OUTPUT_DIR"
        if [[ $scan_type != "all" ]]; then
            nmap ${SCAN_TYPES["$scan_type"]} -vv "$IP" -oN "$OUTPUT_DIR/nmap_$scan_type.txt"
        fi
    done
done
