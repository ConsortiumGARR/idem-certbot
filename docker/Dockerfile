FROM certbot/certbot:v5.1.0

RUN apk update && apk add --no-cache docker-cli bash

# Copy the startup script and make it executable
COPY --chmod=755 docker/start.sh /usr/local/bin/start.sh

# Set the startup command
ENTRYPOINT ["/usr/local/bin/start.sh"]
