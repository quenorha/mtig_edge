#!/bin/bash

	echo "Téléchargement du dépôt"
	docker run -ti --rm -v ${HOME}:/root -v $(pwd):/git alpine/git clone https://github.com/quenorha/mtig_edge
	
	echo "Création network"
	docker network create wago

	echo "Création volumes"
	docker volume create v_grafana
	docker volume create v_influxdb

	echo "Démarrage Mosquitto"
	docker run -d -p 1883:1883 -p 9001:9001 --net=wago --restart=unless-stopped --name c_mosquitto -v $(pwd)/mtig_edge/conf/mosquitto.conf:/mosquitto/config/mosquitto.conf eclipse-mosquitto:latest

	echo "Démarrage InfluxDB"
	docker run -d -p 8086:8086 --name c_influxdb --net=wago --restart unless-stopped -v v_influxdb:/var/lib/influxdb influxdb:1.8.10

	echo "Démarrage Grafana"
	docker run -d -p 3000:3000 --name c_grafana --net=wago --restart unless-stopped -v v_grafana:/var/lib/grafana  -v $(pwd)/mtig_edge/conf/provisioning/:/etc/grafana/provisioning/ grafana/grafana-oss

	echo "Démarrage Telegraf MQTT"
	docker run -d --net=wago --restart=unless-stopped --name=c_telegraf -v $(pwd)/mtig_edge/conf/telegrafmqtt.conf:/etc/telegraf/telegraf.conf:ro telegraf:latest
	
	echo "Démarrage Telegraf Docker metrics"
	docker run -d --user telegraf:$(stat -t /var/run/docker.sock | awk '{ print $6 }') --net=wago --restart=unless-stopped --name=c_telegrafdocker -v /var/run/docker.sock:/var/run/docker.sock -v /root/conf/telegrafdocker.conf:/etc/telegraf/telegraf.conf:ro telegraf:latest
	
	echo "Démarrage Telegraf Speedtest"
	docker run -ti --rm -v ${HOME}:/root -v $(pwd):/git alpine/git clone https://github.com/quenorha/speedtest
	docker build -t wago/speedtest:1.0 $(pwd)/speedtest
	docker run -d --name c_speedtest -v /root/speedtest-storage:/var/log/speedtest wago/speedtest:1.0
	docker run -d --name=c_telegraf_speedtest -v $(pwd)/speedtest:/var/log/speedtest -v $(pwd)/speedtest/telegraf_speedtest.conf:/etc/telegraf/telegraf.conf --network=wago telegraf

	echo "Démarrage Telegraf SNMP"
    docker run -ti --rm -v ${HOME}:/root -v $(pwd):/git alpine/git clone https://github.com/quenorha/snmp_monitoring
	docker build -t wago/telegrafsnmp:1.0 $(pwd)/snmp_monitoring
	docker run -d --net=wago --restart=unless-stopped --name=c_telegrafsnmp -v $(pwd)/snmp_monitoring/telegrafsnmp.conf:/etc/telegraf/telegraf.conf:ro wago/telegrafsnmp:1.0

	echo "Démarrage vnstat"
    docker run -d --restart=unless-stopped --network=host -e HTTP_PORT=8685 -v /etc/localtime:/etc/localtime:ro -v /etc/timezone:/etc/timezone:ro --name vnstat vergoh/vnstat

    echo "Démarrage Telegraf Weather"
    docker run -d --net=wago --restart=unless-stopped --name=c_telegrafweather -v $(pwd)/mtig_edge/conf/telegrafweather.conf:/etc/telegraf/telegraf.conf:ro telegraf:latest

    echo "Démarrage Telegraf Modbus PRO2"
	docker run -d --net=wago --restart=unless-stopped --name=c_telegrafmodbusPRO2 -v $(pwd)/mtig_edge/conf/telegrafmodbusPRO2.conf:/etc/telegraf/telegraf.conf:ro telegraf:latest
