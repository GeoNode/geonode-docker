#!/bin/bash
# Resolve a writable home directory for the user running the container.
# This file is sourced by entrypoint.sh and set_geoserver_auth.sh.
#
# Order of resolution:
#   1. GEOSERVER_HOME, if set explicitly (must be writable).
#   2. /root, when running as root (backward compatible behavior).
#   3. The home directory from /etc/passwd, if it is not "/" and is writable
#      (e.g. /home/geoserver for the built-in "geoserver" user, UID 1000).
#   4. /tmp, for arbitrary UIDs that have no usable passwd entry
#      (e.g. OpenShift injects a random UID with HOME=/).
#
# GEOSERVER_HOME and HOME are exported with the resolved value.

if [ -z "${GEOSERVER_HOME:-}" ]; then
    if [ "$(id -u)" = "0" ]; then
        GEOSERVER_HOME=/root
    else
        _passwd_home="$(getent passwd "$(id -u)" | cut -d: -f6)"
        if [ -n "${_passwd_home}" ] && [ "${_passwd_home}" != "/" ] && [ -w "${_passwd_home}" ]; then
            GEOSERVER_HOME="${_passwd_home}"
        else
            echo "No writable home directory for UID $(id -u) in /etc/passwd, using /tmp" >&2
            GEOSERVER_HOME=/tmp
        fi
        unset _passwd_home
    fi
fi

if [ ! -d "${GEOSERVER_HOME}" ] || [ ! -w "${GEOSERVER_HOME}" ]; then
    echo "ERROR: GEOSERVER_HOME='${GEOSERVER_HOME}' is not a writable directory for the current user (UID $(id -u))." >&2
    echo "       When running as a non-root user, set GEOSERVER_HOME to a writable path (e.g. /tmp)." >&2
    exit 1
fi

export GEOSERVER_HOME
export HOME="${GEOSERVER_HOME}"
export OVERRIDE_ENV="${GEOSERVER_HOME}/.override_env"
