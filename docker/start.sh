#!/bin/bash

# Register ACME account
echo "[setup][START] Register ACME account."
certbot register \
    --email $EMAIL_ADMIN \
    --server $SERVER_URL \
    --eab-kid $KEY_ID \
    --eab-hmac-key $HMAC_KEY \
    --non-interactive --agree-tos 2>&1
echo "[setup][START] ACME account registration done!"

# Exec del supervisor
echo "[setup][START] Starting supervisord."
exec /usr/bin/supervisord -c /etc/supervisord.conf
