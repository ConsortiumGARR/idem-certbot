#!/bin/bash

ip_addresses=("{{ ippriv_first_cnode }}" "{{ ippriv_second_cnode }}" "{{ ippriv_third_cnode }}" "{{ ippriv_fourth_cnode }}")

if [ -d "/srv/idem-certbot" ]; then
    tar -cf - --exclude last_update --absolute-names /srv/idem-certbot | sha1sum > /srv/idem-certbot/last_update
    for HOST_IP in "${ip_addresses[@]}"
    do
        rsync -a -s -e "ssh -i /home/certbot/.ssh/id_ed25519_certbot" /srv/idem-certbot/ certbot@$HOST_IP:/srv/idem-certbot/
	if [ "$?" -eq "0" ]; then
            echo "$(date): Rsync della cartella /srv/idem-certbot correttamente effettuato! - Host: $HOST_IP" >> /var/log/cron.log 2>&1
        fi
    done
fi

