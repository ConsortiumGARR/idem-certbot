#!/bin/bash
set -euo pipefail
trap "exit" SIGHUP SIGINT SIGTERM

# Always required variables
for VAR in EMAIL_ADMIN DOMAINS_LIST; do
  if [ -z "${!VAR}" ]; then
    echo "[setup] Missing variable: $VAR. Please set it with -e '$VAR=' or check your docker-compose configuration."
    exit 1
  fi
done

# Check if EAB variables are set, if not, we will use standard Let's Encrypt registration
USE_EAB=true
for VAR in SERVER_URL KEY_ID HMAC_KEY; do
  if [ -z "${!VAR:-}" ]; then
    USE_EAB=false
    break
  fi
done
echo "[setup] USE_EAB=$USE_EAB"

# Register ACME account if not already registered
echo "[registration] Register ACME account."

if $USE_EAB; then
    echo "[registration] Using ACME EAB."
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
else
    echo "[registration] Using Let's Encrypt standard."
    if ! certbot register \
            --email "$EMAIL_ADMIN" \
            --agree-tos \
            --non-interactive 2>&1 | grep -q "There is an existing account"; then
        echo "[registration] ACME account registration done!"
    else
        echo "[registration] ACME account already exists, skipping registration."
    fi
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

      if $USE_EAB; then
          certbot certonly \
              --standalone \
              --email "$EMAIL_ADMIN" \
              --server "$SERVER_URL" \
              --eab-kid "$KEY_ID" \
              --eab-hmac-key "$HMAC_KEY" \
              "${domain_args[@]}" \
              --key-type rsa \
              --rsa-key-size 3072 \
              --quiet --non-interactive --agree-tos 2>&1
      else
          certbot certonly \
              --standalone \
              --email "$EMAIL_ADMIN" \
              "${domain_args[@]}" \
              --key-type rsa \
              --rsa-key-size 3072 \
              --quiet --non-interactive --agree-tos 2>&1
      fi
      if [ $? -eq 0 ]; then
          echo "[certificates] Certificate for $domain created successfully."
      else
          echo "[certificates] Error: Failed to create certificate for $domain!" >&2
      fi
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
