```shell
docker build -t consul-8377 .
docker run -it --name consul-8377 --rm -v $(pwd):/root consul-8377
docker exec -it consul-8377 ./test.sh
```
