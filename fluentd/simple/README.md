# 非常简单的 fluentd 收集日志例子

## 使用 Docker 日志驱动

`docker run` 提供了 `--log-driver` 及 `--log-opt` 的参数。直接配置其参数，其日志就会转发给指定的日志驱动。

比如这个例子中的 `nginx` 服务，在其 `docker run` 里就是这样指定的：

```bash
docker run -d \
    --name nginx \
    -p 3000:80 \
    --log-driver fluentd \
    --log-opt fluentd-address=localhost:24224 \
    --log-opt tag="my.docker.tag.{{.Name}}" \
    nginx
```

这里面要求使用 `fluentd` 的 `log-driver`，并且配置了两个选项 `--log-opt`。

* `fluentd-address=localhost:24224`: 这是配置 fluentd 服务的地址和端口，这个例子中其实不需要这个配置，因为 fluentd 就跑在了本地，而 `fluentd-address` 默认就是 `localhost:24224`。在实际环境中，可能会有集中的 `fluentd` 服务器，这里需要填写实际的地址。
* `tag="my.docker.tag.{{.Name}}"`: 这是配置 fluentd 的 `tag`。这个 tag 会伴随这条日志，在后面的 fluentd 处理中，比如 `<filter>` 或者 `<match>` 中就可以根据不同的 `tag` 进行不同的处理。在这个例子中，我随便写了个标签 `my.docker.tag.{{.Name}}`。前半部分 `my.docker.tag.` 是固定的，而后半部分是动态的，`{{.Name}}` 会提取当前容器名，不同的容器这里的值不同。这是 Go 模板语法，在 docker 命令中很常见。

## fluentd.conf 的配置

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

这里的配置非常简单。fluentd 的配置大体可以分三段去考虑：

* 从哪里来？
* 怎么处理？
* 送到哪里去？

这里由于使用 Docker 的内置日志驱动，所以“从哪里来？”的问题很简单，就是从 `forward` 来，既通过 fluentd `24224/tcp` 来。因此 `<source>` 只有一行配置。

由于在这个例子中只是简单地 `nginx` 日志。所以关于“怎么处理？”的问题也比较简单，可以从 `<filter>` 中看到，就是利用正则表达式去解析收到的日志罢了。

这是个最简单的例子，调试时也应该从简单到难，所以我让fluentd 收集到日之后直接走标准输出。这样子无需处理 `-v` 绑定目录会碰到的权限之类的问题，直接 `docker logs` 既可看到结果。

## 启动

先启动日志服务

```bash
docker run -d \
    --name fluentd \
    -p 24224:24224 \
    -v "$(pwd)/fluentd.conf":/fluentd/etc/fluentd.conf \
    -e FLUENTD_CONF=fluentd.conf \
    fluent/fluentd
```

然后可以启动需要记录日志的服务

```bash
docker run -d \
    --name nginx \
    -p 3000:80 \
    --log-driver fluentd \
    --log-opt fluentd-address=localhost:24224 \
    --log-opt tag="my.docker.tag.{{.Name}}" \
    nginx
```

然后产生一些日志

```bash
curl localhost:3000
```

## 查看 fluentd 收集到的日志

```bash
docker logs fluentd
```
