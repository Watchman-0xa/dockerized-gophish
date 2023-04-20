FROM gophish/gophish:latest
MAINTAINER Jet

USER root

ENV CONFIG_FILE config.json
ENV CRT_FILE example.crt
ENV KEY_FILE example.key

#RUN apt-get update && \
#        apt-get dist-upgrade -y && \
#        apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/gophish

RUN mv config.json config.json.bkp

COPY config.json .
COPY quersystem.tiraquelibras.com.crt .
COPY quersystem.tiraquelibras.com.key .

RUN chown app: $CONFIG_FILERUN 
RUN chown app: $CRT_FILERUN 
RUN chown app: $KEY_FILE

EXPOSE 3333 81

ENTRYPOINT ["./gophish"]
