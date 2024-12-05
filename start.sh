#!/bin/bash

certbot register \
    --email $EMAIL_RAO \
    --server https://acme.sectigo.com/v2/OV \
    --eab-kid $KEY_ID \
    --eab-hmac-key $HMAC_KEY \
    --non-interactive --agree-tos 2>&1

if [ ! -d "/etc/letsencrypt/live/$IDEM_RT_DOMAIN" ]; then
    certbot certonly \
        --standalone \
        --email $EMAIL_RAO \
        --server https://acme.sectigo.com/v2/OV \
        --domain $IDEM_RT_DOMAIN,$IDEM_RT_ALIAS \
	--key-type rsa \
        --rsa-key-size 3072 \
        --quiet --non-interactive --agree-tos 2>&1
fi

if [ ! -d "/etc/letsencrypt/live/$IDEM_MDX_DOMAIN" ]; then
    certbot certonly \
    --standalone \
    --email $EMAIL_RAO \
    --server https://acme.sectigo.com/v2/OV \
    --domain $IDEM_MDX_DOMAIN,$IDEM_MDX_1ALIAS,$IDEM_MDX_2ALIAS,$IDEM_MDX_3ALIAS \
    --key-type rsa \
    --rsa-key-size 3072 \
    --quiet --non-interactive --agree-tos 2>&1
fi

if [ ! -d "/etc/letsencrypt/live/$IDEM_MDA_DOMAIN" ]; then
    certbot certonly \
    --standalone \
    --email $EMAIL_RAO \
    --server https://acme.sectigo.com/v2/OV \
    --domain $IDEM_MDA_DOMAIN,$IDEM_MDA_1ALIAS \
    --key-type rsa \
    --rsa-key-size 3072 \
    --quiet --non-interactive --agree-tos 2>&1
fi

if [ ! -d "/etc/letsencrypt/live/$EDUID_IDP_DOMAIN" ]; then
    certbot certonly \
    --standalone \
    --email $EMAIL_RAO \
    --server https://acme.sectigo.com/v2/OV \
    --domain $EDUID_IDP_DOMAIN \
    --key-type rsa \
    --rsa-key-size 3072 \
    --quiet --non-interactive --agree-tos 2>&1
fi

# Rimuovi file statici e ricrea symlink
max_number() {
    local max=0
    for file in "/etc/letsencrypt/archive/$1"/cert*.pem; do
        if [[ $file =~ cert([0-9]+).pem ]]; then
            num="${BASH_REMATCH[1]}"
            if (( num > max )); then
                max=$num
            fi
        fi
    done
    echo "$max"
}

for folder in "$IDEM_RT_DOMAIN" "$IDEM_MDX_DOMAIN" "$EDUID_IDP_DOMAIN" 
do
    max=$(max_number "$folder")
    echo "numero massimo nella cartella $max"

    echo "Eliminazione dei certificati da cartella live ..."
    rm -f "/etc/letsencrypt/live/$folder/cert.pem"
    rm -f "/etc/letsencrypt/live/$folder/chain.pem"
    rm -f "/etc/letsencrypt/live/$folder/fullchain.pem"
    rm -f "/etc/letsencrypt/live/$folder/privkey.pem"

    echo "Creazione symlink ..."
    ln -s "/etc/letsencrypt/archive/$folder/cert$max.pem" "/etc/letsencrypt/live/$folder/cert.pem"
    ln -s "/etc/letsencrypt/archive/$folder/chain$max.pem" "/etc/letsencrypt/live/$folder/chain.pem"
    ln -s "/etc/letsencrypt/archive/$folder/fullchain$max.pem" "/etc/letsencrypt/live/$folder/fullchain.pem"
    ln -s "/etc/letsencrypt/archive/$folder/privkey$max.pem" "/etc/letsencrypt/live/$folder/privkey.pem"
done

cron

# Mantenere il container attivo anche dopo i comandi precedenti
exec tail -f /var/log/letsencrypt/letsencrypt.log
