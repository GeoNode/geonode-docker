ARG NGINX_VERSION=1.28.0
FROM nginx:${NGINX_VERSION}-alpine

RUN apk add --no-cache openssl inotify-tools vim

WORKDIR /etc/nginx/

RUN mkdir -p /etc/nginx/html &&\
    touch /etc/nginx/html/index.html

ADD nginx.conf.envsubst nginx.https.available.conf.envsubst ./
ADD geonode.conf.envsubst ./sites-enabled/

ADD docker-autoreload.sh docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
RUN chmod +x /docker-autoreload.sh
RUN chmod +x /docker-entrypoint.sh

CMD ["nginx", "-g", "daemon off;"]
