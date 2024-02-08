#!/bin/bash

ip_addresses=("{{ ippriv_second_cnode }}" "{{ ippriv_third_cnode }}")

if [ -d "/opt/idem-certbot" ]; then
    tar -cf - --exclude last_update --absolute-names /opt/idem-certbot | sha1sum > /opt/idem-certbot/last_update
    for HOST_IP in "${ip_addresses[@]}"
    do
        rsync -rl -s -e "ssh -i /home/certbot/.ssh/id_ed25519_certbot -o 'StrictHostKeyChecking=no'" /opt/idem-certbot/ certbot@$HOST_IP:/opt/idem-certbot/
	if [ "$?" -eq "0" ]; then
            echo "$(date): Rsync della cartella /opt/idem-certbot correttamente effettuato! - Host: $HOST_IP" >> /var/log/cron.log 2>&1
        fi
    done
fi

