FROM python:2.7.9
MAINTAINER Ariel Núñez<ariel@terranodo.io>                                                                                       

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# This section is borrowed from the official Django image but adds GDAL and others
RUN apt-get update && apt-get install -y \
		gcc \
		gettext \
		postgresql-client libpq-dev \
		sqlite3 \
                python-gdal python-psycopg2 \
                python-imaging python-lxml \
	--no-install-recommends && rm -rf /var/lib/apt/lists/*


# To understand the next section (the need for requirements.txt and setup.py)
# Please read: https://packaging.python.org/requirements/

# Copy the requirements first to avoid having to re-do it when the code changes.
# Requirements in requirements.txt are pinned to specific version
# usually the output of a pip freeze
ONBUILD COPY requirements.txt /usr/src/app/
ONBUILD RUN pip install --no-cache-dir -r requirements.txt

# Do this as late as possible so that reinstalling dependencies is a manual
# process triggered by a new build.
# Requirements in setup.py are not pinned to specific versions.
ONBUILD COPY . /usr/src/app
# We believe every Django app/project should be pip installable.
ONBUILD RUN pip install -e /usr/src/app

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
