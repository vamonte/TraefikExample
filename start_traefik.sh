#!/usr/bin/env bash

exec docker service create \
  --mode global \
  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
  --publish target=80,published=80 \
  --publish mode=host,target=8080,published=8080 \
  --name=my_traefik \
  --constraint node.role==manager \
  --network my_stack_network \
  --label traefik.enable=false \
  containous/traefik:v1.1.2 \
  --docker --debug --docker.swarmmode --docker.watch --web
