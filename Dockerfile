FROM consul:1.8.0

WORKDIR /root
VOLUME /root

CMD \
  while true; do consul agent -server -node server1 -data-dir /tmp/server1 -bind 127.0.0.1 -server-port 8201 -serf-lan-port 8301 -serf-wan-port 8401 -http-port 8501 -dns-port 8601 -retry-join 127.0.0.1:8302 -retry-join 127.0.0.1:8303 -bootstrap; done  & \
  while true; do consul agent -server -node server2 -data-dir /tmp/server2 -bind 127.0.0.1 -server-port 8202 -serf-lan-port 8302 -serf-wan-port 8402 -http-port 8502 -dns-port 8602 -retry-join 127.0.0.1:8301 -retry-join 127.0.0.1:8303           ; done  & \
  while true; do consul agent -server -node server3 -data-dir /tmp/server3 -bind 127.0.0.1 -server-port 8203 -serf-lan-port 8303 -serf-wan-port 8403 -http-port 8503 -dns-port 8603 -retry-join 127.0.0.1:8301 -retry-join 127.0.0.1:8302           ; done
