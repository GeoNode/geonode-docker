#!/bin/bash
set -e

# Resolve a writable home directory (supports root, the built-in "geoserver"
# user and arbitrary UIDs). Exports GEOSERVER_HOME, HOME and OVERRIDE_ENV.
source /usr/local/bin/geoserver_home.sh
echo "Running as UID $(id -u), GID $(id -g), GEOSERVER_HOME='${GEOSERVER_HOME}'"

[ -f "${GEOSERVER_HOME}/.bashrc" ] && source "${GEOSERVER_HOME}/.bashrc"

# When running as non-root, create group-writable files, so any UID of the
# root group (GID 0) can use the data directory (e.g. a different UID after a
# redeploy on OpenShift).
# catalina.sh applies its own umask (default 0027) from the UMASK variable.
if [ "$(id -u)" != "0" ]; then
    umask 0002
    export UMASK="${UMASK:-0002}"
fi

# Start from a clean override file at every start
: > "${OVERRIDE_ENV}"

# create/populate the datadir
mkdir -p "$GEOSERVER_DATA_DIR"

if [ ! -w "$GEOSERVER_DATA_DIR" ]; then
    echo "ERROR: GEOSERVER_DATA_DIR='${GEOSERVER_DATA_DIR}' is not writable by the current user (UID $(id -u), GID $(id -g))." >&2
    echo "       Give ownership of the volume to this UID, or to group 0 with group write permission." >&2
    exit 1
fi

if [ ! -f "${GEOSERVER_DATA_DIR}/global.xml" ]; then
    echo "${GEOSERVER_DATA_DIR}/global.xml not found."

    # needing a tmp extraction because the zip contains /data/ as root
    echo "Extracting default data skeleton archive to temp dir..."
    TMP_EXTRACT="$(mktemp -d)"
    unzip -q "$GEOSERVER_SHARE_DIR/geoserver-data-skeleton.zip" -d "$TMP_EXTRACT"
    echo "Moving default data skeleton archive directly to volume..."
#    mv "$TMP_EXTRACT"/data/* "$TMP_EXTRACT"/data/.* "$GEOSERVER_DATA_DIR/" 2>/dev/null || true
    mv -v "$TMP_EXTRACT"/data/* "$TMP_EXTRACT"/data/.* "$GEOSERVER_DATA_DIR/" || true
    rm -rf "$TMP_EXTRACT"
    if [ "$(id -u)" != "0" ]; then
        # the archive keeps its own permissions: make the extracted files group-writable
        find "$GEOSERVER_DATA_DIR" -mindepth 1 -user "$(id -u)" -exec chmod g=u {} +
    fi

    echo "Extraction complete."
else
    echo "Existing GeoServer data configuration detected. Skipping extraction."
fi

# control the values of LB settings if present
if [ -n "$GEONODE_LB_HOST_IP" ];
then
    echo "GEONODE_LB_HOST_IP is defined and not empty with the value '$GEONODE_LB_HOST_IP' "
    echo export GEONODE_LB_HOST_IP=${GEONODE_LB_HOST_IP} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_LB_HOST_IP is either not defined or empty setting the value to 'django' "
    echo export GEONODE_LB_HOST_IP=django >> "${OVERRIDE_ENV}"
    export GEONODE_LB_HOST_IP=django
fi

if [ -n "$GEONODE_LB_PORT" ];
then
    echo "GEONODE_LB_HOST_IP is defined and not empty with the value '$GEONODE_LB_PORT' "
    echo export GEONODE_LB_PORT=${GEONODE_LB_PORT} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_LB_PORT is either not defined or empty setting the value to '8000' "
    echo export GEONODE_LB_PORT=8000 >> "${OVERRIDE_ENV}"
    export GEONODE_LB_PORT=8000
fi

if [ -n "$GEOSERVER_LB_HOST_IP" ];
then
    echo "GEOSERVER_LB_HOST_IP is defined and not empty with the value '$GEOSERVER_LB_HOST_IP' "
    echo export GEOSERVER_LB_HOST_IP=${GEOSERVER_LB_HOST_IP} >> "${OVERRIDE_ENV}"
else
    echo "GEOSERVER_LB_HOST_IP is either not defined or empty setting the value to 'geoserver' "
    echo export GEOSERVER_LB_HOST_IP=geoserver >> "${OVERRIDE_ENV}"
    export GEOSERVER_LB_HOST_IP=geoserver
fi

if [ -n "$GEOSERVER_LB_PORT" ];
then
    echo "GEOSERVER_LB_PORT is defined and not empty with the value '$GEOSERVER_LB_PORT' "
    echo export GEOSERVER_LB_PORT=${GEOSERVER_LB_PORT} >> "${OVERRIDE_ENV}"
else
    echo "GEOSERVER_LB_PORT is either not defined or empty setting the value to '8000' "
    echo export GEOSERVER_LB_PORT=8080 >> "${OVERRIDE_ENV}"
    export GEOSERVER_LB_PORT=8080
fi

# If DATABASE_HOST is not set in the environment, use the default value
if [ -n "$DATABASE_HOST" ];
then
    echo "DATABASE_HOST is defined and not empty with the value '$DATABASE_HOST' "
    echo export DATABASE_HOST=${DATABASE_HOST} >> "${OVERRIDE_ENV}"
else
    echo "DATABASE_HOST is either not defined or empty setting the value to 'db' "
    echo export DATABASE_HOST=db >> "${OVERRIDE_ENV}"
    export DATABASE_HOST=db
fi

# If DATABASE_PORT is not set in the environment, use the default value
if [ -n "$DATABASE_PORT" ];
then
    echo "DATABASE_PORT is defined and not empty with the value '$DATABASE_PORT' "
    echo export DATABASE_PORT=${DATABASE_PORT} >> "${OVERRIDE_ENV}"
else
    echo "DATABASE_PORT is either not defined or empty setting the value to '5432' "
    echo export DATABASE_PORT=5432 >> "${OVERRIDE_ENV}"
    export DATABASE_PORT=5432
fi

# If GEONODE_GEODATABASE_USER is not set in the environment, use the default value
if [ -n "$GEONODE_GEODATABASE" ];
then
    echo "GEONODE_GEODATABASE is defined and not empty with the value '$GEONODE_GEODATABASE' "
    echo export GEONODE_GEODATABASE=${GEONODE_GEODATABASE} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_GEODATABASE is either not defined or empty setting the value '${COMPOSE_PROJECT_NAME}_data' "
    echo export GEONODE_GEODATABASE=${COMPOSE_PROJECT_NAME}_data >> "${OVERRIDE_ENV}"
    export GEONODE_GEODATABASE=${COMPOSE_PROJECT_NAME}_data
fi

# If GEONODE_GEODATABASE_USER is not set in the environment, use the default value
if [ -n "$GEONODE_GEODATABASE_USER" ];
then
    echo "GEONODE_GEODATABASE_USER is defined and not empty with the value '$GEONODE_GEODATABASE_USER' "
    echo export GEONODE_GEODATABASE_USER=${GEONODE_GEODATABASE_USER} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_GEODATABASE_USER is either not defined or empty setting the value '$GEONODE_GEODATABASE' "
    echo export GEONODE_GEODATABASE_USER=${GEONODE_GEODATABASE} >> "${OVERRIDE_ENV}"
    export GEONODE_GEODATABASE_USER=${GEONODE_GEODATABASE}
fi

# If GEONODE_GEODATABASE_USER is not set in the environment, use the default value
if [ -n "$GEONODE_GEODATABASE_PASSWORD" ];
then
    echo "GEONODE_GEODATABASE_PASSWORD is defined and not empty with the value '$GEONODE_GEODATABASE_PASSWORD' "
    echo export GEONODE_GEODATABASE_PASSWORD=${GEONODE_GEODATABASE_PASSWORD} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_GEODATABASE_PASSWORD is either not defined or empty setting the value '${GEONODE_GEODATABASE}' "
    echo export GEONODE_GEODATABASE_PASSWORD=${GEONODE_GEODATABASE} >> "${OVERRIDE_ENV}"
    export GEONODE_GEODATABASE_PASSWORD=${GEONODE_GEODATABASE}
fi

# If GEONODE_GEODATABASE_SCHEMA is not set in the environment, use the default value
if [ -n "$GEONODE_GEODATABASE_SCHEMA" ];
then
    echo "GEONODE_GEODATABASE_SCHEMA is defined and not empty with the value '$GEONODE_GEODATABASE_SCHEMA' "
    echo export GEONODE_GEODATABASE_SCHEMA=${GEONODE_GEODATABASE_SCHEMA} >> "${OVERRIDE_ENV}"
else
    echo "GEONODE_GEODATABASE_SCHEMA is either not defined or empty setting the value to 'public'"
    echo export GEONODE_GEODATABASE_SCHEMA=public >> "${OVERRIDE_ENV}"
    export GEONODE_GEODATABASE_SCHEMA=public
fi

if [ ! -z "${GEOSERVER_JAVA_OPTS}" ]
then
    echo "GEOSERVER_JAVA_OPTS is filled so I replace the value of '$JAVA_OPTS' with '$GEOSERVER_JAVA_OPTS'"
    export JAVA_OPTS=${GEOSERVER_JAVA_OPTS}
fi

# control the value of NGINX_BASE_URL variable
if [ -z `echo ${NGINX_BASE_URL} | sed 's/http:\/\/\([^:]*\).*/\1/'` ]
then
    echo "NGINX_BASE_URL is empty so I'll use the default Geoserver base url"
    echo "Setting GEOSERVER_LOCATION='${SITEURL}'"
    echo export GEOSERVER_LOCATION=${SITEURL} >> "${OVERRIDE_ENV}"
else
    echo "NGINX_BASE_URL is filled so GEOSERVER_LOCATION='${NGINX_BASE_URL}'"
    echo "Setting GEOSERVER_LOCATION='${NGINX_BASE_URL}'"
    echo export GEOSERVER_LOCATION=${NGINX_BASE_URL} >> "${OVERRIDE_ENV}"
fi

if [ -n "$SUBSTITUTION_URL" ];
then
    echo "SUBSTITUTION_URL is defined and not empty with the value '$SUBSTITUTION_URL'"
    echo "Setting GEONODE_LOCATION='${SUBSTITUTION_URL}' "
    echo export GEONODE_LOCATION=${SUBSTITUTION_URL} >> "${OVERRIDE_ENV}"
else
    echo "SUBSTITUTION_URL is either not defined or empty so I'll use the default GeoNode location "
    echo "Setting GEONODE_LOCATION='http://${GEONODE_LB_HOST_IP}:${GEONODE_LB_PORT}' "
    echo export GEONODE_LOCATION=http://${GEONODE_LB_HOST_IP}:${GEONODE_LB_PORT} >> "${OVERRIDE_ENV}"
fi

# set basic tagname
TAGNAME=( "baseUrl" "authApiKey" )

if ! [ -f ${GEOSERVER_DATA_DIR}/security/auth/geonodeAuthProvider/config.xml ]
then
    echo "Configuration file '$GEOSERVER_DATA_DIR'/security/auth/geonodeAuthProvider/config.xml is not available so it is gone to skip "
else
    # backup geonodeAuthProvider config.xml
    cp ${GEOSERVER_DATA_DIR}/security/auth/geonodeAuthProvider/config.xml ${GEOSERVER_DATA_DIR}/security/auth/geonodeAuthProvider/config.xml.orig
    # run the setting script for geonodeAuthProvider
    /usr/local/bin/set_geoserver_auth.sh ${GEOSERVER_DATA_DIR}/security/auth/geonodeAuthProvider/config.xml ${GEOSERVER_DATA_DIR}/security/auth/geonodeAuthProvider/ ${TAGNAME[@]} > /dev/null 2>&1
fi

# backup geonode REST role service config.xml
cp "${GEOSERVER_DATA_DIR}/security/role/geonode REST role service/config.xml" "${GEOSERVER_DATA_DIR}/security/role/geonode REST role service/config.xml.orig"
# run the setting script for geonode REST role service
/usr/local/bin/set_geoserver_auth.sh "${GEOSERVER_DATA_DIR}/security/role/geonode REST role service/config.xml" "${GEOSERVER_DATA_DIR}/security/role/geonode REST role service/" ${TAGNAME[@]} > /dev/null 2>&1

# set oauth2 filter tagname
TAGNAME=( "cliendId" "clientSecret" "accessTokenUri" "userAuthorizationUri" "redirectUri" "checkTokenEndpointUrl" "logoutUri" )

# backup geonode-oauth2 config.xml
cp ${GEOSERVER_DATA_DIR}/security/filter/geonode-oauth2/config.xml ${GEOSERVER_DATA_DIR}/security/filter/geonode-oauth2/config.xml.orig
# run the setting script for geonode-oauth2
/usr/local/bin/set_geoserver_auth.sh ${GEOSERVER_DATA_DIR}/security/filter/geonode-oauth2/config.xml ${GEOSERVER_DATA_DIR}/security/filter/geonode-oauth2/ "${TAGNAME[@]}" > /dev/null 2>&1

# set global tagname
TAGNAME=( "proxyBaseUrl" )

# backup global.xml
cp ${GEOSERVER_DATA_DIR}/global.xml ${GEOSERVER_DATA_DIR}/global.xml.orig
# run the setting script for global configuration
/usr/local/bin/set_geoserver_auth.sh ${GEOSERVER_DATA_DIR}/global.xml ${GEOSERVER_DATA_DIR}/ ${TAGNAME[@]} > /dev/null 2>&1

# NOTE: the xom/bcprov exclusion in catalina.properties is applied at build time
# (see Dockerfile), so the image can run with a read-only root filesystem.

# templating for this docker image we should also do it for other configuration files

declare -a geoserver_datadir_template_dirs=("geofence")

for template in ${geoserver_datadir_template_dirs[*]}; do
    if [ "$template" == "geofence" ]; then
        cp -vR $GEOSERVER_SHARE_DIR/templates/$template/* ${GEOSERVER_DATA_DIR}/geofence

        for f in $(find ${GEOSERVER_DATA_DIR}/geofence/ -type f -name "*.envsubst"); do
            echo -e "Evaluating template\n\tSource: $f\n\tDest: ${f%.envsubst}"
            envsubst < "$f" > "${f%.envsubst}"
            rm -vf "$f"
        done
    fi
done

# configure CORS (inspired by https://github.com/oscarfonts/docker-geoserver)
# if enabled, this will add the filter definitions
# to the end of the web.xml
# (this will only happen if our filter has not yet been added before)
# The result is written to a temp file and copied back, so only the file (not
# its directory) needs to be writable by the current user.
_WEBXML="$CATALINA_HOME/webapps/geoserver/WEB-INF/web.xml"
if [ "${GEOSERVER_CORS_ENABLED}" = "true" ] || [ "${GEOSERVER_CORS_ENABLED}" = "True" ]; then
  if grep -q DockerGeoServerCorsFilter "$_WEBXML"; then
    echo "CORS filter already present in $_WEBXML"
  elif [ ! -w "$_WEBXML" ]; then
    echo "WARNING: $_WEBXML is not writable by UID $(id -u), CORS filter NOT enabled" >&2
  else
    echo "Enable CORS for $_WEBXML"
    _WEBXML_TMP="$(mktemp)"
    sed "\:</web-app>:i\\
    <filter>\n\
      <filter-name>DockerGeoServerCorsFilter</filter-name>\n\
      <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
      <init-param>\n\
          <param-name>cors.allowed.origins</param-name>\n\
          <param-value>${GEOSERVER_CORS_ALLOWED_ORIGINS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
          <param-name>cors.allowed.methods</param-name>\n\
          <param-value>${GEOSERVER_CORS_ALLOWED_METHODS}</param-value>\n\
      </init-param>\n\
      <init-param>\n\
        <param-name>cors.allowed.headers</param-name>\n\
        <param-value>${GEOSERVER_CORS_ALLOWED_HEADERS}</param-value>\n\
      </init-param>\n\
    </filter>\n\
    <filter-mapping>\n\
      <filter-name>DockerGeoServerCorsFilter</filter-name>\n\
      <url-pattern>/*</url-pattern>\n\
    </filter-mapping>" "$_WEBXML" > "$_WEBXML_TMP"
    cat "$_WEBXML_TMP" > "$_WEBXML"
    rm -f "$_WEBXML_TMP"
    unset _WEBXML_TMP
  fi
fi
unset _WEBXML

if [ "${FORCE_REINIT:-false}" = "true" ] || [ "${FORCE_REINIT:-false}" = "True" ] || [ ! -e "${GEOSERVER_DATA_DIR}/geoserver_init.lock" ]; then
    # Run async configuration, it needs GeoServer to be up and running
    nohup /usr/local/bin/configure_geoserver.sh &
fi

# start tomcat
exec env JAVA_OPTS="${JAVA_OPTS}" catalina.sh run
