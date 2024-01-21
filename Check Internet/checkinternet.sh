#!/bin/bash

# Define log paths, rotation settings, and ntfy server
LOG_DIR="x"
ROTATE_DAYS=7
NTFY_SERVER="http://localhost:8080"  # Adjust as needed

# Check for speedtest-cli and install if needed
if ! command -v speedtest-cli &> /dev/null; then
  log_message "INFO" "$LOG_FILE" "Installing speedtest-cli..."
  sudo apt-get install speedtest-cli -y
fi

# Function to manage log files
create_log_file() {
  local date=$(date +'%Y-%m-%d')
  local log_file="$LOG_DIR/connectivity_log_$date.txt"
  if [[ ! -f "$log_file" ]]; then
    touch "$log_file"
    logrotate -f /etc/logrotate.d/connectivity_logs
  fi
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
  if [[ $ping_status -eq 0 ]]; then
    ping_time=$(echo "$ping_result" | grep time= | awk '{print $2}')
    log_message "INFO" "$log_file" "Connected (ping: $ping_time ms)"
  else
    log_message "ERROR" "$log_file" "Ping failed: $ping_result"
    ntfy -server "$NTFY_SERVER" send "Connectivity Alert: Ping failed"
  fi

  # DNS resolution test
  dns_time=$(dig @8.8.8.8 google.com A +time=2 -4 | grep time= | awk '{print $2}')
  if [[ -n "$dns_time" ]]; then
    log_message "INFO" "$log_file" "DNS: $dns_time ms"
  else
    log_message "WARN" "$log_file" "DNS resolution failed"
  fi

  # Speedtest (if speedtest-cli is available)
  if command -v speedtest-cli &> /dev/null; then
    download_speed=$(speedtest-cli --simple | grep Download: | awk '{print $2}')
    upload_speed=$(speedtest-cli --simple | grep Upload: | awk '{print $2}')
    log_message "INFO" "$log_file" "Download speed: $download_speed"
    log_message "INFO" "$log_file" "Upload speed: $upload_speed"
  else
    log_message "WARN" "$log_file" "speedtest-cli not available, skipping speed test"
  fi

  # Custom action on disconnection
  if [[ $ping_status -ne 0 ]]; then
    pihole restartdns  # Restart Pi-hole DNS on disconnection
  fi

  sleep 60
done

# Set up automatic log rotation for weekly cycles
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
