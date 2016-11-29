# fluentd 日志收集的例子

Fluentd 收集日志很方便，[官网文档](http://docs.fluentd.org/articles/quickstart)其实说的很清楚。各种参数以及[配置](http://docs.fluentd.org/categories/recipes)还有[示例](http://docs.fluentd.org/categories/data-archiving)很多。我这里针对 Docker 举几个简单地例子。

* [simple](simple): 这是一个很简单的例子，用 `docker run` 做的日志收集
* [compose](compose): 一般实际环境中，会用 compose 之类的工具，避免太长的命令导致疏漏。这里是使用 Docker Compose 的简单的例子。
* [mongo](mongo): 前两个例子中的 fluentd 收集到日之后直接标准输出，这样方便调试。这个例子中，日志将会转发给 mongodb。
