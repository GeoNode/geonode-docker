# geoserver-docker

[GeoServer](http://geoserver.org) is an open source server for sharing geospatial data.
This is a docker image that eases setting up a GeoServer running specifically for [GeoNode](https://github.com/GeoNode/geoserver-geonode-ext) with an additional separated data directory.

The image is based on the official Tomcat 9 image

## Installation

This image is available as a [trusted build on the docker hub](https://registry.hub.docker.com/r/geonode/geoserver/), and is the recommended method of installation.
Simple pull the image from the docker hub.

```bash
$ docker pull geonode/geoserver
```

Alternatively you can build the image locally

```bash
$ git clone https://github.com/geonode/geoserver-docker.git
$ cd geoserver-docker
$ docker build -t "geonode/geoserver" .
```

## Quick start

You can quick start the image using the command line

```bash
$ docker run --name "geoserver" -v /var/run/docker.sock:/var/run/docker.sock -d -p 8080:8080 geonode/geoserver
```

Point your browser to `http://localhost:8080/geoserver` and login using GeoServer's default username and password:

* Username: admin
* Password: geoserver


## Configuration

### Data volume

This GeoServer container keeps its configuration data at `/geoserver_data/data` which is exposed as volume in the dockerfile.
The volume allows for stopping and starting new containers from the same image without losing all the data and custom configuration.

You may want to map this volume to a directory on the host. It will also ease the upgrade process in the future. Volumes can be mounted by passing the `-v` flag to the docker run command:

```bash
-v /your/host/data/path:/geoserver_data/data
```

#### GeoServer Data Directory Initialization

When running GeoNode via Docker Compose, the core `geoserver` container automatically manages its own persistent configurations. On the very first boot, if the assigned volume is completely empty, an internal initialization step automatically extracts a preconfigured data archive directly into the volume space.

This setup contains the default preloaded `GEOSERVER_DATA_DIR` settings (including custom GeoNode extensions, workspaces, and security providers) required for GeoServer to communicate with Django and the database seamlessly.

#### Customizing or Building the Base Data Directory Locally
If you need to change the base fallback configuration, alter the default zip asset reference built into the core geoserver image:

```Bash
docker build --build-arg GEOSERVER_VERSION=2.24.x -t geonode/geoserver:latest ./docker/geoserver
```

#### Storage and Persistence
Because the default configurations are extracted dynamically at runtime, your master `docker-compose.yml` must map a named volume or host directory to the target path:

```YAML
services:
  geoserver:
    image: geonode/geoserver:latest
    environment:
      - GEOSERVER_DATA_DIR=/geoserver_data/data
    volumes:
      - geoserver-data-dir:/geoserver_data/data
```      
Subsequent container restarts will detect the existing configuration files (such as global.xml) and safely skip the extraction phase, ensuring all runtime additions, styles, and layer maps are completely preserved.


#### Persistance behavior

If you run:

```bash
docker-compose stop
```

Data are retained in the *GEOSERVER_DATA_DIR* and can then be mounted in a new GeoServer instance by running again:

```bash
docker-compose up
```

If you run:

```bash
docker-compose down
```

Data are completely gone but you can ever start from the base GeoServer Data Directory built for Geonode.

### Running as a non-root user

The image runs as `root` by default (backward compatible), but it can run as a non-root user, also with an arbitrary UID (e.g. OpenShift `restricted` SCC, or Kubernetes `runAsNonRoot`).

The image contains a `geoserver` user (UID `1000` by default, build argument `GEOSERVER_UID`) that is member of the root group (GID `0`).
All the paths that must be writable at runtime (`/usr/local/tomcat`, `/geoserver_data`, the user home) are owned by GID `0` with group permissions equal to the owner ones.
For this reason any UID can run the container, if its group is `0`:

```bash
docker run --user 1000:0 -p 8080:8080 geonode/geoserver
docker run --user 4711:0 -p 8080:8080 geonode/geoserver
```

or in `docker-compose.yml`:

```yaml
services:
  geoserver:
    user: "1000:0"
```

The entrypoint needs a writable home directory, which is resolved in this order:

1. `GEOSERVER_HOME`, if set (the container stops with an error if it is not writable).
2. `/root`, when running as root.
3. The home directory from `/etc/passwd` (e.g. `/home/geoserver` for UID `1000`), if it is not `/` and it is writable.
4. `/tmp`, for arbitrary UIDs with no usable passwd entry.

The data directory volume must be writable by the UID, or by GID `0` with group write permission.
A new named volume gets the permissions of the image directory, so no action is necessary.
For a bind mount or an existing volume created by a root container, fix the permissions first, e.g.:

```bash
chown -R 1000:0 /your/host/data/path && chmod -R g=u /your/host/data/path
```

#### Read-only root filesystem

The image supports a read-only root filesystem (e.g. Kubernetes `readOnlyRootFilesystem: true`):
the static Tomcat changes are made at build time and the JVM log is written to `/tmp/jvm.log`.
In this case mount writable volumes (e.g. `emptyDir`) on `/tmp`, `/usr/local/tomcat/logs`, `/usr/local/tomcat/work`, `/usr/local/tomcat/temp`, and on `GEOSERVER_HOME` if it is not `/tmp`.
CORS (`GEOSERVER_CORS_ENABLED`) changes `web.xml` at startup, so it is skipped with a warning when this file is read-only.

### Database

GeoServer recommends the usage of a spatial database

#### PostGIS container (PostgreSQL + GIS Extension)

If you want to use a [PostGIS](http://postgis.org/) container, you can link it to this image. You're free to use any PostGIS container.
An example with [kartooza/postgis](https://registry.hub.docker.com/u/kartoza/postgis/) image:

```bash
$ docker run -d --name="postgis" kartoza/postgis
```

For further information see [kartooza/postgis](https://registry.hub.docker.com/u/kartoza/postgis/).

Now start the GeoServer instance by adding the `--link` option to the docker run command:

```bash
--link postgis:postgis
```
