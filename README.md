# web_agent
An HTTP API Server for VerneMQ

# NOTE
if you install VerneMQ from binary package ,  your must find out your VerneMQ which erlang version use (https://github.com/vernemq/vernemq/releases)
and goto https://www.erlang.org/downloads to find the version of Erlang to install.

# Getting Started

```shell
git clone https://github.com/boboxiaodd/web_agent 
cd web_agent
wget https://s3.amazonaws.com/rebar3/rebar3 && chmod +x rebar3 #Download Rebar3
rebar3 compile
chmod +x server-ctl
./server-ctl start
```
# Config
priv/app.config
```erlang
{port, 7000},  %% HTTP server Listen port
{mqtt_node, 'VerneMQ@127.0.0.1'}
```
