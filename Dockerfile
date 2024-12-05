# Use Alpine as the base image (very small)
FROM alpine:3.18
LABEL Authors="Mario Di Lorenzo <mario.dilorenzo@garr.it>"

# Set non-interactive environment
ENV PYTHONUNBUFFERED=1

# Install Python, cron, and other minimal dependencies
RUN apk add --no-cache \
    python3 py3-pip \
    bash \
    dcron

# Create a Python virtual environment for Certbot
RUN python3 -m venv /opt/certbot && \
    /opt/certbot/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/certbot/bin/pip install --no-cache-dir certbot certbot-nginx && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Copy the cron file for Certbot renewal
COPY certbot_cron /etc/crontabs/root

# Copy the startup script and make it executable
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set the startup command
CMD ["/usr/local/bin/start.sh"]
