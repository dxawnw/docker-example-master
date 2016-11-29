# MySQL 主从复制集群示例

很多人希望 Docker 官方 [mysql镜像](https://hub.docker.com/_/mysql/) 可以提供主从复制集群的功能，其实这个功能不需要官方镜像支持，因为 mysql 镜像已经提供了良好的定制能力，允许使用初始化脚本进行定制。这个示例就是演示如何使用 mysql 初始化脚本。

官方 MySQL 镜像允许使用初始化脚本，所有位于 `/docker-entrypoint-initdb.d/` 目录下的文件，如果是 `.sh`, `.sql`, `.sql.gz`，那么都会被执行。这个主从复制集群的例子就是使用 `.sh` 脚本进行定制。

在这里我借用了 [docker-library/mysql#43](https://github.com/docker-library/mysql/pull/43) 的脚本，修改后命名为 `replica.sh`。如脚本内容所述，这里新增了5个环境变量可以用于后期定制。

- `MYSQL_REPLICA_USER`: 创建该复制任务用户
- `MYSQL_REPLICA_PASS`
- `MYSQL_MASTER_SERVER`: 指定主 mysql 服务器的位置，在示例我利用的是Docker内置服务发现，用的是服务名
- `MYSQL_MASTER_PORT`: 可选，默认为 `3306`
- `MYSQL_MASTER_WAIT_TIME`: 等候主服务器启动的时间（单位为秒）

`Dockerfile` 的内容非常简单：

```Dockerfile
FROM mysql:5.7
MAINTAINER Tao Wang <twang2218@gmail.com>
COPY replica.sh /docker-entrypoint-initdb.d/
```

仅仅是将 `replica.sh` 复制到 `/docker-entrypoint-initdb.d/`。

演示这个mysql主从复制集群，我这里使用 `docker-compose.yml`：

```yaml
version: '2'
services:
    master:
        build: .
        restart: unless-stopped
        ports:
            - "3306:3306"
        environment:
            - MYSQL_ROOT_PASSWORD=master_passw0rd
            - MYSQL_REPLICA_USER=replica
            - MYSQL_REPLICA_PASS=replica_Passw0rd
        command: ["mysqld", "--log-bin=mysql-bin", "--server-id=1"]
    slave:
        build: .
        restart: unless-stopped
        ports:
            - "3307:3306"
        environment:
            - MYSQL_ROOT_PASSWORD=slave_passw0rd
            - MYSQL_REPLICA_USER=replica
            - MYSQL_REPLICA_PASS=replica_Passw0rd
            - MYSQL_MASTER_SERVER=master
            - MYSQL_MASTER_WAIT_TIME=10
        command: ["mysqld", "--log-bin=mysql-bin", "--server-id=2"]
```

然后只需要 `docker-compose up -d`，这个 mysql 主从复制集群就开始运行了。

停止只需要使用 `docker-compose down` 即可。
