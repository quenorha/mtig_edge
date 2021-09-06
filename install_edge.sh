#!/bin/bash

	echo "Téléchargement des fichiers de configuration"
	mkdir /root/config
	wget https://raw.githubusercontent.com/quenorha/mtig_edge/main/conf/mosquitto.conf -O /root/config/mosquitto.conf
	wget https://raw.githubusercontent.com/quenorha/mtig_edge/main/conf/telegraf.conf -O /root/config/telegraf.conf
	
	echo "Téléchargement image Portainer"
	docker pull portainer/portainer-ce:2.6.1

	echo "Téléchargement image Mosquitto"
	docker pull eclipse-mosquitto:2.0.11
	
	echo "Téléchargement image Influxdb"
	docker pull influxdb:1.8.6
	
	echo "Téléchargement image Grafana"
	docker pull grafana/grafana:8.0.0
	
	echo "Téléchargement image Telegraf"
	docker pull telegraf:1.19.1
	
	echo "Création network"
	docker network create wago

	echo "Création volumes"
	docker volume create v_portainer
	docker volume create v_grafana
	docker volume create v_influxdb

	echo "Démarrage Portainer"
	docker run -d -p 8000:8000 -p 9000:9000 --name=c_portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v v_portainer:/data portainer/portainer-ce:2.6.1

	echo "Démarrage Mosquitto"
	docker run -d -p 1883:1883 -p 9001:9001 --restart=unless-stopped --name c_mosquitto -v /root/config/mosquitto.conf:/mosquitto/config/mosquitto.conf eclipse-mosquitto:2.0.11

	echo "Démarrage InfluxDB"
	docker run -d -p 8086:8086 --name c_influxdb --net=wago --restart unless-stopped -v v_influxdb influxdb:1.8.6

	echo "Démarrage Grafana"
	docker run -d -p 3000:3000 --name c_grafana -e GF_PANELS_DISABLE_SANITIZE_HTML=true --net=wago --restart unless-stopped -v v_grafana grafana/grafana:8.0.0

	echo "Démarrage Telegraf"
	docker run -d --net=wago --restart=unless-stopped --name=c_telegraf -v /root/config/telegraf.conf:/etc/telegraf/telegraf.conf:ro telegraf:1.19.3
	