#!/bin/bash

# Create log directory if it doesn't exist
mkdir -p x

# Define log paths, rotation settings, and ntfy server
LOG_DIR="x"
ROTATE_DAYS=7
NTFY_SERVER="http://localhost:83"  # Adjust as needed

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

  # Ping test with error handling and logging
  ping_result=$(ping -c 1 -W 1 8.8.8.8 2>&1)
  ping_status=$?
  if [[ -n "$ping_time" ]]; then
    ping_time=$(echo "$ping_result" | grep time= | awk '{print $2}')
    log_message "INFO" "$log_file" "Connected (ping: $ping_time ms)"
  else
    log_message "ERROR" "$log_file" "Ping failed: $ping_result"
    ntfy -server "$NTFY_SERVER" send "Connectivity Alert: Ping failed"
    pihole restartdns  # Restart Pi-hole DNS on disconnection
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
