# fluentd 收集日志并输出到 mongodb

## 日志服务 Compose 文件

日志服务的配置文件 [log/docker-compose.yml](log/docker-compose.yml):

```yml
version: '2'
services:
    fluentd:
        build: .
        ports:
            - "24224:24224"
        volumes:
            - ./fluentd.conf:/fluentd/etc/fluentd.conf
        environment:
            - "FLUENTD_CONF=fluentd.conf"
    mongo:
        image: mongo:3
        ports:
            - "27017:27017"
        volumes:
            - data:/data/db
volumes:
    data:
```

这个例子中的日志服务比之前的[compose](../compose)增加了一个 `mongo` 服务，以运行 mongodb 并接受日志。

`fluentd` 和 `mongo` 服务都会运行于同一个 docker compose 创建的网络里，因此它们之间可以使用 Docker 内置 DNS 进行服务发现，直接使用对方服务名即可。

这里 `mongo` 的数据存储于名为 `data` 的**命名卷**。

## fluentd 的 Dockerfile

如果仔细观察上面的 compose 配置文件，就会发现，这里我没有使用 `fluent/fluentd`，而是构建了一个镜像。

因为在这个例子中日志将输出到 mongodb，因此我们需要安装 `fluent-plugin-mongo` 插件，并且还需要 `bson_ext` 的ruby库。因此我们需要对 `fluent/fluentd` 进行进一步的定制。

```Dockerfile
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
```

从这个 Dockerfile 中可以看到我之前说过的，安装 `bson_ext` 以及 `fluent-plugin-mongo`。

这里需要注意用户的问题。最佳实践里，服务进程应该尽量不以 `root` 用户运行，而应该建立合适的用户去运行。很多镜像都遵循了这个实践，`fluent/fluentd` 也不例外。因此，定制的时候需要先变换用户到 `root` 进行系统定制行为，然后在降回 `fluent` 用户进行插件安装。这就是这两个 `USER root`，`USER fluent` 的原因。

## fluentd.conf 配置文件

配置文件基本和之前一样，只是 `<match>` 输出部分改为了 mongodb

```xml
<source>
    @type forward
</source>

<filter **>
    @type parser
    format /^(?<remote>[^ ]*) (?<host>[^ ]*) (?<user>[^ ]*) \[(?<time>[^\]]*)\] "(?<method>\S+)(?: +(?<path>[^\"]*) +\S*)?" (?<code>[^ ]*) (?<size>[^ ]*)(?: "(?<referer>[^\"]*)" "(?<agent>[^\"]*)" "(?<forward>[^\"]*)")?$/
    time_format %d/%b/%Y:%H:%M:%S %z
    key_name log
    reserve_data true
</filter>

<match **>
    @type mongo
    host mongo
    port 27017
    database logs

    tag_mapped
    collection misc
    time_key time
    flush_interval 10s
    ignore_invalid_record true
</match>
```

需要注意的是，这里 `host mongo` 中的 `mongo` 是 mongodb 的服务名，这里我是利用了 Docker 内置的DNS服务发现。fluentd 和 mongodb 都运行于同一个网络，所以可以互相发现。因此这里无需使用IP。

## 启动

先启动日志服务

```bash
cd log
docker-compose up -d
```

然后可以启动需要记录日志的服务

```bash
cd service
docker-compose up -d
```

然后产生一些日志

```bash
curl localhost:3000
```

## 查看mongodb中的日志

```bash
docker-compose exec mongo mongo logs --eval "db.docker.service_web_1.find().pretty()"
```
