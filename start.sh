#!/bin/bash

certbot register --email $EMAIL_RAO --server https://acme.sectigo.com/v2/OV --eab-kid $KEY_ID --eab-hmac-key $HMAC_KEY --non-interactive --agree-tos 2>&1

if [ ! -d "/etc/letsencrypt/live/$IDEM_RT_DOMAIN" ]; then
    certbot certonly --standalone --email $EMAIL_RAO --server https://acme.sectigo.com/v2/OV --domain $IDEM_RT_DOMAIN,$IDEM_RT_ALIAS --rsa-key-size 3072 --quiet --non-interactive --agree-tos 2>&1
fi

if [ ! -d "/etc/letsencrypt/live/$IDEM_MDX_DOMAIN" ]; then
    certbot certonly --standalone --email $EMAIL_RAO --server https://acme.sectigo.com/v2/OV --domain $IDEM_MDX_DOMAIN,$IDEM_MDX_1ALIAS,$IDEM_MDX_2ALIAS,$IDEM_MDX_3ALIAS --rsa-key-size 3072 --quiet --non-interactive --agree-tos 2>&1
fi

cron

exec tail -f /dev/null
