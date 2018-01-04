# switch2osm_dockerfiles

Dockerfiles for building an osm tile server

## Debian Jessie

- docker build the dockerfile (*sudo docker build .*)
- launch (*docker run -dit xxxxxxxxxx*) and execute startup.sh in the /home/osm folder (*sudo docker run -it xxxxxxxxxx* for accessing vm prompt)
- access map viewer at http://your_vm_IP_adress/
