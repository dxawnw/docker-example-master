#!/bin/bash

function up() {
    echo "Starting Fluentd..."

    docker run -d \
        --name fluentd \
        -p 24224:24224 \
        -v "$(pwd)/fluentd.conf":/fluentd/etc/fluentd.conf \
        -e FLUENTD_CONF=fluentd.conf \
        fluent/fluentd

    sleep 2

    echo "Starting Nginx (for some output)..."
    docker run -d \
        --name nginx \
        -p 3000:80 \
        --log-driver fluentd \
        --log-opt fluentd-address=localhost:24224 \
        --log-opt tag="my.docker.tag.{{.Name}}" \
        nginx
}

function down() {
    docker rm -f -v fluentd nginx
}

function test() {
    curl -I localhost:3000
}

function logs() {
    docker logs fluentd
}

function main() {
    Command="$1"
    shift
    case "$Command" in
        up)     up ;;
        down)   down ;;
        test)   test ;;
        logs)   logs ;;
        run)    down && up && test && logs ;;
        *)      echo "Usage: $0 <up|down|test|logs|run>" ;;
    esac
}

main "$@"
