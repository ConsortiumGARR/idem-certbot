#!/bin/bash
set -euo pipefail
trap "exit" SIGHUP SIGINT SIGTERM

for VAR in EMAIL_ADMIN SERVER_URL KEY_ID HMAC_KEY DOMAINS_LIST; do
  if [ -z "${!VAR}" ]; then
    echo "[setup] Missing variable: $VAR. Please set it with -e '$VAR=' or check your docker-compose configuration."
    exit 1
  fi
done

# Register ACME account
echo "[registration] Register ACME account."

if ! certbot register \
        --email "$EMAIL_ADMIN" \
        --server "$SERVER_URL" \
        --eab-kid "$KEY_ID" \
        --eab-hmac-key "$HMAC_KEY" \
        --non-interactive \
        --agree-tos 2>&1 | grep -q "There is an existing account"; then
    echo "[registration] ACME account registration done!"
else
    echo "[registration] ACME account already exists, skipping registration."
fi

# Function to request a new certificate if it doesn't exist
create_cert() {
    local domain="$1"
    local aliases="$2"

    # Build certbot -d arguments
    local domain_args=("-d" "$domain")

    if [ -n "$aliases" ]; then
        IFS=',' read -r -a alias_array <<< "$aliases"
        for a in "${alias_array[@]}"; do
            domain_args+=("-d" "$a")
        done
    fi

    # Check if certificate already exists
    if [ ! -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
        echo "[certificates] Creating certificate for $domain"

        certbot certonly \
            --standalone \
            --email "$EMAIL_ADMIN" \
            --server "$SERVER_URL" \
            "${domain_args[@]}" \
            --key-type rsa \
            --rsa-key-size 3072 \
            --quiet --non-interactive --agree-tos 2>&1
    else
        echo "[certificates] Certificate for $domain already exists."
    fi
}

# Split the DOMAINS_LIST by semicolon (to separate domains)
IFS=';' read -r -a domains <<< "$DOMAINS_LIST"
for domain_info in "${domains[@]}"; do
    # Extract "domain:aliases"
    IFS=':' read -r domain aliases <<< "$domain_info"
    # Ensure aliases is empty if not provided
    aliases="${aliases:-}"
    # Call certificate creation
    create_cert "$domain" "$aliases"
done

# Renew loop
# Default to 12 hours if not set
CHECK_FREQ="${CHECK_FREQ:-12}"

# Validate CHECK_FREQ (must be a positive integer)
if ! [[ "$CHECK_FREQ" =~ ^[0-9]+$ ]]; then
  echo "[renew] Error: CHECK_FREQ must be a positive integer (hours). Current value: '$CHECK_FREQ'"
  exit 1
fi

echo "[renew] Check frequency set to $CHECK_FREQ hours."
echo -e "\n* [renew] Starting renew loop."
sleep "${CHECK_FREQ}h"

while true; do
  echo -e "\n* [renew] Running renew loop at $(date '+%Y-%m-%d %H:%M:%S')..."

  if certbot renew -q; then
    echo "* [renew] Certificate renew process finished."
  else
    echo "* [renew] Error: Failed to execute the renew command!" >&2
  fi

  echo "* [renew] Next check in $CHECK_FREQ hours"
  sleep "${CHECK_FREQ}h"
done
