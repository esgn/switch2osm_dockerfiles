#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
service postgresql start
while ! pg_isready
do
    echo "waiting for database to start"
    sleep 5
done
/etc/init.d/renderd start
service apache2 start
