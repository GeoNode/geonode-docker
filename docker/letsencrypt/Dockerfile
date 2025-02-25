FROM alpine:latest

RUN apk add --no-cache certbot 

# Installing scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY crontab /crontab

RUN chmod +x /docker-entrypoint.sh && \
    crontab /crontab && \
    rm /crontab

# Setup the entrypoint
ENTRYPOINT ["./docker-entrypoint.sh"]

# We run cron in foreground to update the certificates
CMD ["/usr/sbin/crond", "-f"]
