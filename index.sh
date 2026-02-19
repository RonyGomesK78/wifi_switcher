#!/bin/bash

# Define your WiFi connection names exactly as they appear in NetworkManager
# (use `nmcli connection show` to verify – these are the profile names, not necessarily broadcast SSIDs)
SSIDS=("Wifu_5G" "Wifu" "Wufi 5GHZ" "Wufi")

get_signal() {
    local ssid="$1"
    nmcli -g SSID,SIGNAL device wifi list | \
    while IFS=':' read -r listed_ssid sig; do
        if [[ "$listed_ssid" == "$ssid" ]]; then
            echo "$sig"
            break
        fi
    done | head -n1
}

# Force a fresh scan
nmcli device wifi rescan >/dev/null 2>&1
sleep 4  # usually sufficient

best_ssid=""
best_signal=0

for ssid in "${SSIDS[@]}"; do
    signal=$(get_signal "$ssid")
    if [[ -n "$signal" && "$signal" -gt "$best_signal" ]]; then
        best_signal="$signal"
        best_ssid="$ssid"
    fi
done

if [[ -n "$best_ssid" ]]; then
    # Get current connection name (profile name)
    current=$(nmcli -t -f NAME,TYPE connection show --active | grep ':802-11-wireless$' | cut -d: -f1)
    
    if [[ "$current" != "$best_ssid" ]]; then
        echo "Switching to stronger network: $best_ssid (signal: $best_signal dBm)"
        nmcli connection up "$best_ssid"
    else
        echo "Already connected to the strongest available: $best_ssid ($best_signal)"
    fi
else
    echo "None of the specified networks are currently visible."
fi