# Use Alpine as the base image
FROM alpine:3.20
LABEL Authors="Mario Di Lorenzo <mario.dilorenzo@garr.it>"

# Set non-interactive environment
ENV PYTHONUNBUFFERED=1

# Install Python, cron, and other minimal dependencies
RUN apk add --no-cache \
    python3 py3-pip \
    bash \
    dcron \
    rsyslog \
    supervisor

# Create a Python virtual environment for Certbot
RUN python3 -m venv /opt/certbot && \
    /opt/certbot/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/certbot/bin/pip install --no-cache-dir certbot && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Copy files for Certbot request and renewal
COPY docker/certs.sh /usr/local/bin/certs.sh
RUN chmod +x /usr/local/bin/certs.sh
COPY docker/certbot_cron /etc/crontabs/root

# Copy Supervisor config
RUN mkdir -p /var/log/supervisor/ \
    && mkdir -p /var/run/supervisord
RUN chmod -R 0755 /var/log/supervisor
COPY docker/supervisord.conf /etc/supervisord.conf

# Copy the startup script and make it executable
COPY docker/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set the startup command
CMD ["/usr/local/bin/start.sh"]
