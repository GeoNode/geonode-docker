FROM python:2.7.14
MAINTAINER GeoNode development team

RUN mkdir -p /usr/src/{app,geonode}

WORKDIR /usr/src/app

# This section is borrowed from the official Django image but adds GDAL and others
RUN apt-get update && apt-get install -y \
		gcc \
		gettext \
		postgresql-client libpq-dev \
		sqlite3 \
                python-gdal python-psycopg2 \
                python-imaging python-lxml \
                python-dev libgdal-dev \
                python-ldap \
                libmemcached-dev libsasl2-dev zlib1g-dev \
                python-pylibmc \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY wait-for-databases.sh /usr/bin/wait-for-databases
RUN chmod +x /usr/bin/wait-for-databases

# Upgrade pip
RUN pip install --upgrade pip

# To understand the next section (the need for requirements.txt and setup.py)
# Please read: https://packaging.python.org/requirements/

# python-gdal does not seem to work, let's install manually the version that is
# compatible with the provided libgdal-dev
RUN pip install GDAL==1.10 --global-option=build_ext --global-option="-I/usr/include/gdal"

# install shallow clone of geonode master branch
RUN git clone --depth=1 git://github.com/GeoNode/geonode.git --branch 2.7.x /usr/src/geonode
RUN cd /usr/src/geonode/; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .


RUN cp /usr/src/geonode/tasks.py /usr/src/app/
RUN cp /usr/src/geonode/entrypoint.sh /usr/src/app/

RUN chmod +x /usr/src/app/tasks.py \
    && chmod +x /usr/src/app/entrypoint.sh


# use latest master
ONBUILD RUN cd /usr/src/geonode/; git pull ; pip install --upgrade --no-cache-dir -r requirements.txt; pip install --upgrade -e .
ONBUILD COPY . /usr/src/app
ONBUILD RUN pip install --upgrade --no-cache-dir -r /usr/src/app/requirements.txt
ONBUILD RUN pip install -e /usr/src/app --upgrade

# Update the requirements from the local env in case they differ from the pre-built ones.
ONBUILD COPY requirements.txt /usr/src/app/
ONBUILD RUN pip install --upgrade --no-cache-dir -r requirements.txt

ONBUILD COPY . /usr/src/app/
ONBUILD RUN pip install --upgrade --no-cache-dir -e /usr/src/app/

EXPOSE 8000

ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
CMD ["uwsgi", "--ini", "/usr/src/app/uwsgi.ini"]
