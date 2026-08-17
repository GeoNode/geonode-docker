#!/bin/bash

echo "************************ Configuring GeoServer credentials *****************************"

# Fallback values identical to the original python task
GEOSERVER_LB_PORT="${GEOSERVER_LB_PORT:-8080}"
GEOSERVER_ADMIN_USER="${GEOSERVER_ADMIN_USER:-admin}"
GEOSERVER_ADMIN_PASSWORD="${GEOSERVER_ADMIN_PASSWORD:-geoserver}"
GEOSERVER_FACTORY_PASSWORD="${GEOSERVER_FACTORY_PASSWORD:-geoserver}"
GEOSERVER_DATA_DIR="${GEOSERVER_DATA_DIR:-/geoserver_data/data/}"

REST_URL="http://localhost:${GEOSERVER_LB_PORT}/geoserver/rest/security/self/password"

XML_DATA="<?xml version=\"1.0\" encoding=\"UTF-8\"?><userPassword><newPassword>${GEOSERVER_ADMIN_PASSWORD}</newPassword></userPassword>"

# Retry loop: 1 to 28 attempts, sleeping 2 seconds between each (roughly ~1 minute total timeout)
for cnt in {1..28}; do
    echo "...waiting for GeoServer to pop-up... Attempt ${cnt}"
    
    # Check if GeoServer is responding before attempting PUT
    if curl -fsS -o /dev/null "http://localhost:${GEOSERVER_LB_PORT}/geoserver/"; then
        # Execute the password update request using curl basic auth
        RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
            -u "${GEOSERVER_ADMIN_USER}:${GEOSERVER_FACTORY_PASSWORD}" \
            -H "Content-Type: application/xml" \
            -H "Accept: application/xml" \
            -d "${XML_DATA}" \
            "${REST_URL}")

        echo "Response Code: ${RESPONSE_CODE}"

        if [ "$RESPONSE_CODE" -eq 200 ]; then
            echo "GeoServer admin password updated SUCCESSFULLY!"
            break
        else
            echo "WARNING: GeoServer admin password *NOT* updated: code [${RESPONSE_CODE}]"
        fi
    fi
    
    sleep 2
done

# Initialize the lock file only if configuration succeeded
if [ "${RESPONSE_CODE:-}" -eq 200 ] 2>/dev/null; then
    echo "************************** Writing init lockfile ********************************"
    mkdir -p "${GEOSERVER_DATA_DIR}"
    date > "${GEOSERVER_DATA_DIR}/geoserver_init.lock"
else
    echo "WARNING: GeoServer init lockfile not written because password update did not succeed."
fi
