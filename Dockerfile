FROM debian:stretch
MAINTAINER Sergey Vessart <vessart@ascon.ru>

ARG A_SERVER=localhost:5545
ARG A_DATABASE=pilot-ice_ru
ARG A_LOGIN=root
ARG A_PASSWORD=whale
ARG A_PILOT_SERVER_URL=https://pilot.ascon.ru/release/pilot-server.zip

ENV E_SERVER=$A_SERVER
ENV E_DATABASE=$A_DATABASE
ENV E_LOGIN=$A_LOGIN
ENV E_PASSWORD=$A_PASSWORD
ENV E_PILOT_SERVER_URL=$A_PILOT_SERVER_URL

RUN apt-get update \
&& apt-get -y upgrade \
&& apt-get install wget apt-utils unzip icu-devtools libssl1.0.2 nginx tar supervisor mupdf-tools -y

RUN mkdir /opt/pilot-server \
&& cd /opt/pilot-server \
&& wget --no-check-certificate $E_PILOT_SERVER_URL \
&& unzip pilot-server.zip \
&& chmod +x Ascon.Pilot.Daemon \
&& ./Ascon.Pilot.Daemon --admin ./settings.xml $E_LOGIN $E_PASSWORD \
&& mkdir databases \
&& cd databases \
&& wget --no-check-certificate https://pilot.ascon.ru/release/Databases.zip \
&& unzip Databases.zip \
&& rm Databases.zip \
&& cd ../ \
&& ./Ascon.Pilot.Daemon --db ./settings.xml pilot-ice_ru /opt/pilot-server/databases/pilot-ice_ru/base.dbp /opt/pilot-server/databases/pilot-ice_ru/FileArchive \
&& ./Ascon.Pilot.Daemon --db ./settings.xml pilot-ice_en /opt/pilot-server/databases/pilot-ice_en/base.dbp /opt/pilot-server/databases/pilot-ice_en/FileArchive \
&& ./Ascon.Pilot.Daemon --db ./settings.xml pilot-ecm_ru /opt/pilot-server/databases/pilot-ecm_ru/base.dbp /opt/pilot-server/databases/pilot-ecm_ru/FileArchive \
&& ./Ascon.Pilot.Daemon --db ./settings.xml 3d-storage_ru /opt/pilot-server/databases/3d-storage_ru/base.dbp /opt/pilot-server/databases/3d-storage_ru/FileArchive

RUN mkdir /opt/pilot-web \
&& cd /opt/pilot-web \
&& wget https://github.com/PilotTeam/pilot-web-client-netcorerelease/releases/download/v2.0.4/Release_Linux.zip \
&& unzip Release_Linux.zip \
&& rm Release_Linux.zip \
&& rm appsettings.json \
&& printf "{\nPilotServer:{\n\"Url\":\"http://$E_SERVER\",\n\"Database\":\"$E_DATABASE\"}\n}" > appsettings.json \
&& chmod +x Ascon.Pilot.Web

COPY appsettings.json /opt/pilot-web/appsettings.json

COPY pilot-web.config /etc/nginx/sites-available/pilot-web.config

RUN ln -s /etc/nginx/sites-available/pilot-web.config /etc/nginx/sites-enabled/pilot-web.config \
&& rm /etc/nginx/sites-available/default \
&& service nginx restart

COPY supervisor/* /etc/supervisor/conf.d/

CMD /usr/bin/supervisord -nc /etc/supervisor/supervisord.conf

EXPOSE 80 5545
