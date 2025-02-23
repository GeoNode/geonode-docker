FROM alpine:latest
ARG GEOSERVER_VERSION=2.24.x
ARG BASE_GEOSERVER_DATA_DIR=/geoserver_data

# Some label best practices
# https://www.docker.com/blog/docker-best-practices-using-tags-and-labels-to-manage-docker-image-sprawl/
LABEL org.opencontainers.image.title="GeoNode's Geoserver Data image" \
    org.opencontainers.image.version=${GEOSERVER_VERSION} \
    org.opencontainers.image.vendor="GeoNode Development Team"

ENV TEMP_DOWNLOADED=/tmp/geonode/downloaded \
    GEOSERVER_VERSION=${GEOSERVER_VERSION}

WORKDIR ${TEMP_DOWNLOADED}

COPY download.sh .

# Download required files
RUN apk --no-cache add curl && \
    chmod +x download.sh && \
    sh download.sh $GEOSERVER_VERSION $TEMP_DOWNLOADED && \
    # for debugging
    ls -lart

# preparing the volume
RUN mkdir -p ${BASE_GEOSERVER_DATA_DIR} && \
    cp -r ${TEMP_DOWNLOADED}/data ${BASE_GEOSERVER_DATA_DIR} && \
    chmod -R g=u ${BASE_GEOSERVER_DATA_DIR}/data

VOLUME ${BASE_GEOSERVER_DATA_DIR}/data
