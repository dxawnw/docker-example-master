# Node app 示例

这就是一个简单的 Node.js 的 Web 服务器，守护 `3000` 端口，仅仅返回 `Hello World!`。该示例是演示如何制作 Node.js App 镜像。

# Dockerfile

```Dockerfile
FROM node:latest
MAINTAINER Tao Wang <twang2218@gmail.com>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json /usr/src/app/
RUN npm install
COPY . /usr/src/app

CMD [ "npm", "start" ]
```

`Dockerfile` 很简单，直接借用 `node:onbuild` 的 `Dockerfile` 略作修改。

这里需要注意的是，为了充分利用 `docker build` 的缓存机制，先复制 `package.json` 到工作目录，然后 `npm install` 安装依赖，最后再 `COPY` 应用代码到工作目录，这样不会因为代码的简单改变而重复安装依赖。

# 运行

这里我使用了 `docker-compose.yml` 来定义运行时参数：

```yml
version: '2'
services:
    app:
        build: .
        restart: unless-stopped
        ports:
            - "3000:3000"
```

因此只需简单地 `docker-compose up -d`，该服务即可运行。停止只需要执行 `docker-compose down` 即可。
