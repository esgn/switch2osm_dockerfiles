#!/bin/bash
export LD_LIBRARY_PATH=/usr/local/lib
service postgresql start
sleep 10
/etc/init.d/renderd start
sleep 10
service apache2 start
