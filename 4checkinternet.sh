#!/bin/bash

# Create log directory if it doesn't exist
mkdir -p x

# Define log paths, rotation settings, and ntfy server
LOG_DIR="x"
ROTATE_DAYS=7
#NTFY_SERVER="http://localhost:83"  # Adjust as needed

# Function to manage log files
create_log_file() {
  local date=$(date +'%Y-%m-%d')
  local timestamp=$(date +'%Y-%m-%d_%H-%M-%S')
  local log_file="$LOG_DIR/connectivity_log_$timestamp.txt"
  touch "$log_file"
  logrotate -f /etc/logrotate.d/connectivity_logs
  echo "$log_file"
}

# Function to log messages with timestamps and levels
log_message() {
  local level="$1"
  shift
  echo "$(date +'%Y-%m-%d %H:%M:%S') - [$level] $*"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - [$level] $*" >> "$1"
}

# Check internet connectivity and log results
while true; do
  local log_file=$(create_log_file)

  # Track consecutive ping failures
  failed_pings=0

  # Ping test with error handling and logging
  for i in 1 2 3; do
    ping_result=$(ping -c 1 -W 1 google.com 2>&1)  # Ping google.com
    ping_status=$?

    if [[ $ping_status -eq 0 ]]; then
      ping_time=$(echo "$ping_result" | grep time= | awk '{print $2}')
      log_message "INFO" "$log_file" "Connected (ping google.com: $ping_time ms)"
      failed_pings=0  # Reset counter if successful
      break
    else
      log_message "ERROR" "$log_file" "Ping google.com failed: $ping_result"
      failed_pings=$((failed_pings + 1))
    fi

    sleep 1  # Wait 1 second between pings
  done

  # Restart Pi-hole if 3 consecutive pings failed
  if [[ $failed_pings -eq 3 ]]; then
    log_message "ERROR" "$log_file" "3 consecutive ping failures. Restarting DNS server."
    ntfy -server "$NTFY_SERVER" send "Connectivity Alert: 3 consecutive ping failures"
    pihole restartdns
  fi

  # DNS resolution test
  dns_time=$(dig @8.8.8.8 google.com A +time=2 -4 | grep time= | awk '{print $2}')
  if [[ -n "$dns_time" ]]; then
    log_message "INFO" "$log_file" "DNS: $dns_time ms"
  else
    log_message "WARN" "$log_file" "DNS resolution failed"
  fi

  sleep 60
done

# Create logrotate configuration file if it doesn't exist
if [ ! -f /etc/logrotate.d/connectivity_logs ]; then
  cat <<EOF > /etc/logrotate.d/connectivity_logs
$LOG_DIR/connectivity_log_* {
  daily
  rotate $ROTATE_DAYS
  compress
  delaycompress
  missingok
  notifempty
}
EOF
fi
