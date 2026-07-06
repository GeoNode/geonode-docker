ARG IMAGE_VERSION=9.0.118-jdk17-temurin-jammy
ARG JAVA_HOME=/usr/local/openjdk-11
FROM tomcat:$IMAGE_VERSION

ARG GEOSERVER_VERSION=2.28.4
ARG GEOSERVER_CORS_ENABLED=False
ARG GEOSERVER_CORS_ALLOWED_ORIGINS=*
ARG GEOSERVER_CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,HEAD,OPTIONS
ARG GEOSERVER_CORS_ALLOWED_HEADERS=*
#
# Set GeoServer version and data directory
#
ENV GEOSERVER_VERSION=${GEOSERVER_VERSION}
ENV GEOSERVER_DATA_DIR="/geoserver_data/data"
ENV GEOSERVER_CORS_ENABLED=$GEOSERVER_CORS_ENABLED
ENV GEOSERVER_CORS_ALLOWED_ORIGINS=$GEOSERVER_CORS_ALLOWED_ORIGINS
ENV GEOSERVER_CORS_ALLOWED_METHODS=$GEOSERVER_CORS_ALLOWED_METHODS
ENV GEOSERVER_CORS_ALLOWED_HEADERS=$GEOSERVER_CORS_ALLOWED_HEADERS

RUN apt-get update -y && apt-get -y install --no-install-recommends curl wget unzip procps less gettext-base && rm -rf /var/lib/apt/lists/*

#
# Download and install GeoServer
#
RUN cd /usr/local/tomcat/webapps \
    && wget --no-check-certificate --progress=bar:force:noscroll https://artifacts.geonode.org/geoserver/${GEOSERVER_VERSION}/geoserver.war -O geoserver.war \
    && unzip -q geoserver.war -d geoserver \
    && rm geoserver.war \
    && mkdir -p $GEOSERVER_DATA_DIR

#
# Download datadir zip
# 
ENV GEOSERVER_SHARE_DIR="/usr/local/share/geoserver"
RUN mkdir -p $GEOSERVER_SHARE_DIR $GEOSERVER_SHARE_DIR/templates
RUN wget --no-check-certificate --progress=bar:force:noscroll \
    https://artifacts.geonode.org/geoserver/$GEOSERVER_VERSION/geonode-geoserver-ext-web-app-data.zip \
    -O $GEOSERVER_SHARE_DIR/geoserver-data-skeleton.zip


COPY ./templates $GEOSERVER_SHARE_DIR/templates
COPY ./files/applicationContext.xml /usr/local/tomcat/webapps/geoserver/WEB-INF/classes/applicationContext.xml
COPY ./scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

VOLUME $GEOSERVER_DATA_DIR

ENV JAVA_OPTS="-Djava.awt.headless=true -Dgwc.context.suffix=gwc -XX:+UnlockDiagnosticVMOptions -XX:+LogVMOutput -XX:LogFile=/var/log/jvm.log -XX:MaxPermSize=512m -XX:PermSize=256m -Xms2048m -Xmx2048m -XX:+UseConcMarkSweepGC -XX:ParallelGCThreads=4 -Dfile.encoding=UTF8 -Djavax.servlet.request.encoding=UTF-8 -Djavax.servlet.response.encoding=UTF-8 -Duser.timezone=GMT -Dorg.geotools.shapefile.datetime=false -DGS-SHAPEFILE-CHARSET=UTF-8 -DGEOSERVER_CSRF_DISABLED=true -DPRINT_BASE_URL=http://geoserver:8080/geoserver/pdf -Xbootclasspath/a:/usr/local/tomcat/webapps/geoserver/WEB-INF/lib/marlin-0.9.3.jar -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine"

CMD ["/usr/local/bin/entrypoint.sh"]
