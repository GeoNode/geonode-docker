FROM python:3.8.3-buster
MAINTAINER GeoNode development team

RUN mkdir -p /usr/src/{app,geonode}

WORKDIR /usr/src/app

# Enable postgresql-client-11.2
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -


# This section is borrowed from the official Django image but adds GDAL and others
RUN apt-get update && apt-get install -y \
		gcc zip \
		gettext \
		postgresql-client-11 libpq-dev \
		sqlite3 spatialite-bin libsqlite3-mod-spatialite \
                python3-gdal python3-psycopg2 python3-ldap \
                python3-pil python3-lxml python3-pylibmc \
                python3-dev libgdal-dev \
                libxml2 libxml2-dev libxslt1-dev zlib1g-dev libjpeg-dev \
                libmemcached-dev libsasl2-dev \
                libldap2-dev libsasl2-dev \
                uwsgi uwsgi-plugin-python3 \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*


RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y geoip-bin

COPY wait-for-databases.sh /usr/bin/wait-for-databases
RUN chmod +x /usr/bin/wait-for-databases

# Upgrade pip
RUN pip install pip==20.1

# To understand the next section (the need for requirements.txt and setup.py)
# Please read: https://packaging.python.org/requirements/

#let's install pygdal wheels compatible with the provided libgdal-dev
RUN gdal-config --version | cut -c 1-5 | xargs -I % pip install 'pygdal>=%.0,<=%.999'

# install shallow clone of geonode 2.10.1 branch
RUN git clone --depth=1 git://github.com/GeoNode/geonode.git /usr/src/geonode
RUN cd /usr/src/geonode/; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .


RUN cp /usr/src/geonode/tasks.py /usr/src/app/
RUN cp /usr/src/geonode/entrypoint.sh /usr/src/app/

RUN chmod +x /usr/src/app/tasks.py \
    && chmod +x /usr/src/app/entrypoint.sh


# use 2.10.1
ONBUILD RUN cd /usr/src/geonode/; git pull ; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .
ONBUILD COPY . /usr/src/app
ONBUILD RUN pip install --upgrade --no-cache-dir -r /usr/src/app/requirements.txt
ONBUILD RUN pip install -e /usr/src/app --upgrade

# Update the requirements from the local env in case they differ from the pre-built ones.
ONBUILD COPY requirements.txt /usr/src/app/
ONBUILD RUN pip install --upgrade --no-cache-dir -r requirements.txt

ONBUILD COPY . /usr/src/app/
ONBUILD RUN pip install --upgrade --no-cache-dir -e /usr/src/app/

COPY entrypoint.sh /usr/src/app/
COPY uwsgi.ini /usr/src/app

EXPOSE 8000

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
CMD ["uwsgi", "--ini", "/usr/src/app/uwsgi.ini"]
