FROM fluent/fluentd:v0.12.29
MAINTAINER Tao Wang <twang2218@gmail.com>

USER root
RUN apk --no-cache add \
        --virtual .build_deps \
        build-base \
        ruby-dev \
    && gem install bson_ext \
    && apk del .build_deps

USER fluent
RUN fluent-gem install fluent-plugin-mongo
