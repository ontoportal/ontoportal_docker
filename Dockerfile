FROM alpine:latest

ENV TERM xterm-256color
RUN apk --update --no-cache add \
    bash \
    curl \
    docker \
    docker-compose \
    git \
    iproute2 \ 
    busybox \
    ncurses \
    bind-tools

COPY . /app
RUN chmod +x /app/ontoportal
RUN chmod +x /app/bin/*
RUN chmod +x /app/utils/*
WORKDIR /app

CMD ["/bin/sh", "-c", "/app/ontoportal start --no-provision"]