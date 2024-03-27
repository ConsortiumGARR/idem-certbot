FROM debian:12-slim 
LABEL Authors="Mario Di Lorenzo <mario.dilorenzo@garr.it>"

ENV TZ="Europe/Rome"

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get -y update && apt-get -y upgrade \
    && apt-get install --no-install-recommends -y apt-utils build-essential vim git procps \
    ntp rsync python3-dev python3-pip python3-venv libaugeas0 cron 

#CERTBOT
RUN python3 -m venv /opt/certbot/
RUN /opt/certbot/bin/pip install --upgrade pip
RUN /opt/certbot/bin/pip install certbot certbot-nginx
RUN ln -s /opt/certbot/bin/certbot /usr/bin/certbot
COPY certbot_cron /etc/cron.d/certbot_cron

COPY start.sh /start.sh
RUN chmod a+x /start.sh
CMD ["/start.sh"]
