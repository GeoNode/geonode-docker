ARG NGINX_VERSION=1.25.5
FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine

USER root

RUN apk add --no-cache openssl inotify-tools vim

WORKDIR /etc/nginx

COPY nginx.conf.envsubst ./
COPY nginx.https.available.conf.envsubst ./https/
COPY geonode.conf.envsubst ./sites-enabled/
COPY docker-autoreload.sh docker-entrypoint.sh /

RUN mkdir -p \
        /geonode-certificates/disabled \
        /geonode-certificates/staging \
        /geonode-certificates/production \
        /geonode-certificates/autoissued && \
    mv nginx.conf nginx.conf.orig && \
    touch nginx.conf && \
    chmod -R g=u \
        /geonode-certificates/* \
        nginx.conf \
        ./https/ \
        ./sites-enabled/ && \
    chmod +x /docker-autoreload.sh /docker-entrypoint.sh

USER nginx

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
