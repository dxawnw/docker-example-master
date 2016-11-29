# 用 compose 文件来管理 fluentd

## Compose 文件

这个例子中，将日志服务和Web服务拆分了为两个项目。因此对应有两个 `docker-compose.yml` 文件。

### 日志服务

日志服务的配置文件 [log/docker-compose.yml](log/docker-compose.yml):

```yml
version: '2'
services:
    fluentd:
        image: fluent/fluentd:v0.12.29
        ports:
            - "24224:24224"
        volumes:
            - ./fluentd.conf:/fluentd/etc/fluentd.conf
        environment:
            - "FLUENTD_CONF=fluentd.conf"
```

非常简单，直接用 `fluent/fluentd` 镜像启动，映射端口、挂载配置。没有任何多余的东西。

### Web 服务

Web服务的配置文件 [service/docker-compose.yml](service/docker-compose.yml):

```yml
version: '2'
services:
    web:
        image: nginx:1.11-alpine
        ports:
            - "3000:80"
        logging:
            driver: fluentd
            options:
                fluentd-address: "localhost:24224"
                tag: "docker.{{.Name}}"
```

Web 服务也很简单，就是跑了个 `nginx`，映射端口、配置日志驱动。

这里基本上就是把 [simple](../simple) 中的 `docker run` 改成了 `docker-compose.yml` 而已。

## fluentd.conf 的配置

这里的配置和 `simple` 示例一样。

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
  @type stdout
</match>
```

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

## 查看收集的日志

```bash
cd log
docker-compose logs -f
```
