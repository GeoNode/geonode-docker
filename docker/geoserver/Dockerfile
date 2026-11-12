ARG IMAGE_VERSION=9.0.123-jdk17-temurin-jammy
FROM tomcat:$IMAGE_VERSION

ARG GEOSERVER_VERSION=2.28.x
ARG GEOSERVER_CORS_ENABLED=False
ARG GEOSERVER_CORS_ALLOWED_ORIGINS=*
ARG GEOSERVER_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
ARG GEOSERVER_CORS_ALLOWED_HEADERS=*

# Non-root / arbitrary-UID support.
# The image still runs as root by default (backward compatible). To run it
# rootless, start the container with any UID and group 0 (e.g. `--user 1000:0`,
# or an arbitrary UID injected by OpenShift).
ARG GEOSERVER_UID=1000
ARG GEOSERVER_USER_HOME=/home/geoserver

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="GeoNode's GeoServer image" \
      org.opencontainers.image.version=${GEOSERVER_VERSION} \
      org.opencontainers.image.vendor="GeoNode Development Team"

#
# Set GeoServer version and data directory
#
ENV GEOSERVER_VERSION=${GEOSERVER_VERSION} \
    GEOSERVER_DATA_DIR="/geoserver_data/data" \
    GEOSERVER_SHARE_DIR="/usr/local/share/geoserver" \
    GEOSERVER_CORS_ENABLED=${GEOSERVER_CORS_ENABLED} \
    GEOSERVER_CORS_ALLOWED_ORIGINS=${GEOSERVER_CORS_ALLOWED_ORIGINS} \
    GEOSERVER_CORS_ALLOWED_METHODS=${GEOSERVER_CORS_ALLOWED_METHODS} \
    GEOSERVER_CORS_ALLOWED_HEADERS=${GEOSERVER_CORS_ALLOWED_HEADERS}

RUN apt-get update -y \
    && apt-get -y install --no-install-recommends curl wget unzip procps less gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Unprivileged user, member of the root group (GID 0). Every path that has to
# be writable at runtime is owned by GID 0 with group permissions equal to the
# owner ones (g=u), so any UID running with GID 0 can use it.
RUN set -eux; \
    useradd --uid ${GEOSERVER_UID} --gid 0 --home-dir ${GEOSERVER_USER_HOME} --create-home --shell /bin/bash geoserver; \
    cp /etc/skel/.bashrc ${GEOSERVER_USER_HOME}/.bashrc 2>/dev/null || touch ${GEOSERVER_USER_HOME}/.bashrc; \
    chown -R ${GEOSERVER_UID}:0 ${GEOSERVER_USER_HOME}; \
    chmod -R g=u ${GEOSERVER_USER_HOME}

#
# Download and install GeoServer.
# Ownership and permissions are fixed in the same layer, so the webapp is not
# duplicated in an additional layer.
#
RUN set -eux; \
    cd ${CATALINA_HOME}/webapps; \
    wget --no-check-certificate --progress=bar:force:noscroll \
        https://artifacts.geonode.org/geoserver/${GEOSERVER_VERSION}/geoserver.war -O geoserver.war; \
    unzip -q geoserver.war -d geoserver; \
    rm geoserver.war; \
    # exclude wrong dependencies (done at build time to support a read-only root filesystem)
    sed -i -e 's/xom-\*\.jar/xom-\*\.jar,bcprov\*\.jar/g' ${CATALINA_HOME}/conf/catalina.properties; \
    # create the localhost dir in advance, so Tomcat does not log a misleading error on a read-only root filesystem
    mkdir -p ${CATALINA_HOME}/conf/Catalina/localhost ${GEOSERVER_DATA_DIR}; \
    chown -R ${GEOSERVER_UID}:0 ${CATALINA_HOME} /geoserver_data; \
    chmod -R g=u ${CATALINA_HOME} /geoserver_data

#
# Download datadir zip
#
RUN set -eux; \
    mkdir -p ${GEOSERVER_SHARE_DIR}/templates; \
    wget --no-check-certificate --progress=bar:force:noscroll \
        https://artifacts.geonode.org/geoserver/${GEOSERVER_VERSION}/geonode-geoserver-ext-web-app-data.zip \
        -O ${GEOSERVER_SHARE_DIR}/geoserver-data-skeleton.zip

COPY ./templates ${GEOSERVER_SHARE_DIR}/templates
COPY --chown=${GEOSERVER_UID}:0 ./files/applicationContext.xml ${CATALINA_HOME}/webapps/geoserver/WEB-INF/classes/applicationContext.xml
COPY ./scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

VOLUME ${GEOSERVER_DATA_DIR}

# JVM log goes to /tmp, so it is writable by any UID and with a read-only root filesystem
ENV JAVA_OPTS="-Djava.awt.headless=true -Dgwc.context.suffix=gwc -XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=/tmp/jvm.log -Xms2048m -Xmx2048m -XX:ParallelGCThreads=4 -Dfile.encoding=UTF8 -Djavax.servlet.request.encoding=UTF-8 -Djavax.servlet.response.encoding=UTF-8 -Duser.timezone=GMT -Dorg.geotools.shapefile.datetime=false -DGS-SHAPEFILE-CHARSET=UTF-8 -DGEOSERVER_CSRF_DISABLED=true -DPRINT_BASE_URL=http://geoserver:8080/geoserver/pdf"

EXPOSE 8080

# NOTE: no USER statement. The image runs as root by default (backward compatible).
# To run rootless, use any UID with group 0, e.g. `docker run --user 1000:0 ...`.

CMD ["/usr/local/bin/entrypoint.sh"]
