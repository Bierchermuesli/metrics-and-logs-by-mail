#!/bin/bash

# Debug variable to control logging (set to 1 to enable, 0 to disable)
DEBUG=0
PROMETHEUS_PUSHGATEWAY_IP="100.66.66.116"
PROMETHEUS_PUSHGATEWAY_PORT="9091"

logfile="/tmp/pushgateway_metrics.log"

# logging function
log() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "$1" >> "$logfile"
    fi
}

# Read email from stdin
email=$(tee)
subject=$(echo "$email" | grep -i "^Subject:" | sed 's/Subject: //I')

# Sanitize the subject for the job name 
# - Keep only letters and numbers
# - Replace spaces with underscores
# - Remove all other characters
sanitized_subject=$(echo "$subject" | sed 's/[^a-zA-Z0-9 ]//g' | tr ' ' '_')
log "New meterics recieved for: $sanitized_subject"

# Push metrics from the body of the email (after headers)
body=$(echo "$email" | sed -n '/^$/,$p')

# Further sanitize: Ensure only valid Prometheus metric lines (comments, types, and metric lines)
valid_metrics=$(echo "$body" | grep -E '^(#|[a-zA-Z_:][a-zA-Z0-9_:]*(\{.*\})? [0-9.]+)')

# If no valid metrics are found, exit to prevent pushing invalid data
if [ -z "$valid_metrics" ]; then
    log "No valid Prometheus metrics found. Exiting."
    exit 0
fi
valid_metrics="${valid_metrics}"$'\n'

if [ "$DEBUG" -eq 1 ]; then
  echo "$valid_metrics" > /tmp/last_metrics.log
fi

# Delete all previous stats
curl -X DELETE "http://${PROMETHEUS_PUSHGATEWAY_IP}:${PROMETHEUS_PUSHGATEWAY_PORT}/metrics/job/$sanitized_subject"

# Push metrics to Prometheus Pushgateway and log HTTP response
curl_response=$(curl --silent --show-error --write-out "%{http_code}" --data-binary "$valid_metrics" "http://${PROMETHEUS_PUSHGATEWAY_IP}:${PROMETHEUS_PUSHGATEWAY_PORT}/metrics/job/$sanitized_subject" 2>> "$logfile")

log "Curl HTTP response: $curl_response"

if [[ "$curl_response" -lt 200 || "$curl_response" -ge 300 ]]; then
    log "Error: Failed to push metrics to Prometheus Pushgateway (HTTP $curl_response)"
    #make it silent to avoid mail bounces
    exit 0
fi

# Exit successfully
log "Metrics successfully pushed to Prometheus ${PROMETHEUS_PUSHGATEWAY_IP}/$sanitized_subject"
exit 0
