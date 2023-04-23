FROM alpine:3.14

RUN apk add --no-cache wget

WORKDIR /app

RUN wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy && \
    chmod +x cloud_sql_proxy

