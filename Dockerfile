FROM alpine:latest

RUN apk --update --no-cache add \
    bash \
    curl \
    docker \
    docker-compose \
    git

COPY ontoportal /app/ontoportal
COPY .env /app/.env
RUN chmod +x /app/ontoportal
WORKDIR /app
VOLUME /var/run/docker.sock
CMD ["/bin/sh", "-c", "/app/ontoportal start && tail -f /dev/null"]