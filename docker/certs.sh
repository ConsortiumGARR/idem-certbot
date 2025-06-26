#!/bin/bash

# Function to request a new certificate if not already exists
create_cert() {
    domain=$1
    aliases=$2

    if [ -n "$aliases" ]; then
        domains_arg="$domain,$aliases"
    else
        domains_arg="$domain"
    fi

    if [ ! -d "/etc/letsencrypt/live/$domain" ] || [ ! -f "/etc/letsencrypt/live/$domain/cert.pem" ]; then
        echo "[certs] Creating certificate for $domain"
        certbot certonly \
            --standalone \
            --email $EMAIL_ADMIN \
            --server $SERVER_URL \
            --domain "$domains_arg" \
            --key-type rsa \
            --rsa-key-size 3072 \
            --quiet --non-interactive --agree-tos 2>&1
    else
        echo "[certs] Certificate for $domain already exists."
    fi
}

# Function to get the maximum number of certificates (to determine the latest version)
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

# Function to create symlinks for certificates
create_symlinks() {
    domain=$1
    max=$(max_number "$domain")
    
    echo "Creating symlinks for $domain"
    rm -f /etc/letsencrypt/live/"$domain"/*
    
    ln -s "/etc/letsencrypt/archive/$domain/cert$max.pem" "/etc/letsencrypt/live/$domain/cert.pem"
    ln -s "/etc/letsencrypt/archive/$domain/chain$max.pem" "/etc/letsencrypt/live/$domain/chain.pem"
    ln -s "/etc/letsencrypt/archive/$domain/fullchain$max.pem" "/etc/letsencrypt/live/$domain/fullchain.pem"
    ln -s "/etc/letsencrypt/archive/$domain/privkey$max.pem" "/etc/letsencrypt/live/$domain/privkey.pem"
}

# If DOMAINS_LIST is not set, exit.
if [ -z "$DOMAINS_LIST" ]; then
    echo "[certs] DOMAINS_LIST variable is not set. Run the container with the domains as environment variables."
    exit 1
fi

# Split the DOMAINS_LIST by semicolon (to separate domains)
IFS=';' read -r -a domains <<< "$DOMAINS_LIST"
for domain_info in "${domains[@]}"; do
    # Split each domain_info by colon to get domain and aliases
    IFS=':' read -r domain aliases <<< "$domain_info"
    
    # Split aliases by comma
    IFS=',' read -r -a aliases_array <<< "$aliases"
    aliases_list=$(IFS=, ; echo "${aliases_array[*]}")
    
    create_cert "$domain" "$aliases_list"
    create_symlinks "$domain"
done
