FROM alpine:latest

RUN apk --update --no-cache add \
    bash \
    curl \
    docker \
    docker-compose \
    git

COPY ontoportal /app/ontoportal
COPY run_api.sh /app/run_api.sh
COPY run_ui.sh /app/run_ui.sh

RUN chmod +x /app/ontoportal
RUN chmod +x /app/run_api.sh
RUN chmod +x /app/run_ui.sh


WORKDIR /app

VOLUME /var/run/docker.sock

CMD ["/app/ontoportal", "start"]
