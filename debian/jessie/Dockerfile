# Tested with docker v1.12.6 on ubuntu 16.04.2
FROM debian:jessie

# Maintainer
MAINTAINER psychicLocust <psychiclocust@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# SET PROXY IF NECESSARY
# ENV http_proxy http://host:port
# ENV https_proxy http://host:port

# INSTALL ALL THE NECESSARY PACKAGES
RUN apt-get -qq update
RUN apt-get install -y wget apt-utils
RUN apt-get install -y postgresql-9.4-postgis-2.1 postgresql-contrib-9.4
RUN apt-get install -y osm2pgsql
RUN apt-get install -y autoconf libtool libmapnik-dev apache2 apache2-dev
RUN apt-get install -y curl unzip gdal-bin mapnik-utils node-carto

# CREATE OSM USER (OPTIONAL)
RUN useradd -ms /bin/bash osm

# SETUP DATABASE
USER postgres
RUN /etc/init.d/postgresql start &&\
    createuser osm &&\
    createdb -E UTF8 -T template0 -O osm bourgogne &&\
    psql -c "CREATE EXTENSION hstore;" -d bourgogne &&\
    psql -c "CREATE EXTENSION postgis;" -d bourgogne

# COPY USEFUL FILES
WORKDIR /home/osm
USER osm
COPY startup.sh /home/osm
COPY shutdown.sh /home/osm
COPY index.html /var/www/html
COPY leaflet/ /var/www/html/leaflet

# IMPORT OSM EXTRACT TO DATABASE
# ADJUST --number-processes CORRESPONDING TO YOUR MACHINE CPU
RUN wget https://github.com/gravitystorm/openstreetmap-carto/archive/v2.29.1.tar.gz
RUN tar -xzf v2.29.1.tar.gz

RUN wget http://download.geofabrik.de/europe/france/bourgogne-latest.osm.pbf
USER postgres
RUN /etc/init.d/postgresql start &&\
	sleep 60 &&\
	osm2pgsql --slim -d bourgogne -C 1600 --number-processes 4 --hstore -S openstreetmap-carto-2.29.1/openstreetmap-carto.style bourgogne-latest.osm.pbf

# INSTALL APACHE MOD_TILE
USER osm
RUN wget https://github.com/openstreetmap/mod_tile/archive/6c2cb243e4c8b047950ab8062cd66245f20a5d2f.tar.gz -O mod_tile.tar.gz
RUN tar -xzf mod_tile.tar.gz

WORKDIR /home/osm/mod_tile-6c2cb243e4c8b047950ab8062cd66245f20a5d2f/
RUN ./autogen.sh
RUN ./configure
RUN make

USER root
RUN make install
RUN make install-mod_tile

# COMPUTE STYLE
WORKDIR /home/osm/openstreetmap-carto-2.29.1/
USER osm
RUN ./get-shapefiles.sh
RUN sed -i 's/"dbname": "gis"/"dbname": "bourgogne"/' project.mml
RUN carto project.mml > style.xml

# EDIT CONFIG FILES
USER root
RUN sed -i 's/XML=\/home\/jburgess\/osm\/svn\.openstreetmap\.org\/applications\/rendering\/mapnik\/osm\-local\.xml/XML=\/home\/osm\/openstreetmap-carto-2.29.1\/style.xml/' /usr/local/etc/renderd.conf
RUN sed -i 's/HOST=tile\.openstreetmap\.org/HOST=localhost/' /usr/local/etc/renderd.conf
RUN sed -i 's/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/2.2\/input\//' /usr/local/etc/renderd.conf
RUN sed -i '/^;/ d' /usr/local/etc/renderd.conf

WORKDIR /home/osm/	
RUN cp mod_tile-6c2cb243e4c8b047950ab8062cd66245f20a5d2f/debian/renderd.init /etc/init.d/renderd
RUN chmod a+x /etc/init.d/renderd

RUN sed -i 's/DAEMON=\/usr\/bin\/$NAME/DAEMON=\/usr\/local\/bin\/$NAME/' /etc/init.d/renderd
RUN sed -i 's/DAEMON_ARGS=""/DAEMON_ARGS=" -c \/usr\/local\/etc\/renderd.conf"/' /etc/init.d/renderd
RUN sed -i 's/RUNASUSER=www-data/RUNASUSER=osm/' /etc/init.d/renderd

# CREATE MOD_TILE FOLDER
RUN mkdir -p /var/lib/mod_tile
RUN chown osm:osm /var/lib/mod_tile

# EDIT APACHE CONFIGURATION
RUN echo "LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so" > /etc/apache2/mods-available/tile.load
RUN sed -i '/<\/VirtualHost>/ i \
LoadTileConfigFile \/usr\/local\/etc\/renderd.conf \n \
ModTileRenderdSocketName \/var\/run\/renderd\/renderd.sock \n \
ModTileRequestTimeout 0 \n \
ModTileMissingRequestTimeout 30' /etc/apache2/sites-enabled/000-default.conf
RUN ln -s /etc/apache2/mods-available/tile.load /etc/apache2/mods-enabled/

EXPOSE 80
