# TraefikExample
Just an example to show how to run Træfɪk in swarm mode with docker 1.13.
Træfɪk is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease (https://traefik.io/).


## How to:

### 1) Network:

The first step is to create an overlay network that will be used by the stack and the Træfɪk service. 
You may use the docker API to create your own network or use the next command to create the example network.

```shell
 ./create_stack_network.sh
 
```
To check the result :
```shell
docker network ls

NETWORK ID          NAME                DRIVER              SCOPE
....
nfnu3t0v9c82        my_stack_network    overlay             swarm    <----- your new overlay network
.....

```


### 2) Run the Træfɪk service:
To run the Træfɪk service you may use the start_traefik script. You will find below an explanation of the script.
```shell
./start_traefik.sh
```

#### Script explanations:
```shell
exec docker service create \
  --mode global \   <---- deploy on each node if the condition is True. (on all the manager here)
  --mount type=bind,source=/var/run/docker.sock,destination=/var/run/docker.sock \
  --publish target=80,published=80 \   <----- the port used to contact Træfɪk
  --publish mode=host,target=8080,published=8080 \   <------ the port used by the interface. Mode=host because by default the binding is on the service and not on each containers.
  --name=my_traefik \
  --constraint node.role==manager \   <------ the Træfɪk containers should be on the managers because they have to request the swarm api that is enabled only on the managers.
  --network my_stack_network \
  --label traefik.enable=false \      <------ Træfɪk will ignore its own service when it will requests the running services to the swarm API
  containous/traefik:v1.1.2 \
  --docker --debug --docker.swarmmode --docker.watch --web

```

#### To check the result :
```shell

docker service ls

ID            NAME        MODE    REPLICAS  IMAGE
t86pknkfmosm  my_traefik  global  1/1       containous/traefik:v1.1.2    <----- your new Træfɪk service
```

As long as docker pulls the image of your service, the replicas value will be 0/1.
To check the state of the service, you have to use the next command.

```shell
docker service ps <service_id>  # t86pknkfmosm
```

### 2) Run your stack:

The last step is to run your stack with the next command. The explications about the compose file are in the next part.

```shell
docker stack deploy --compose-file=docker-compose.yml my-stack
```
#### Compose file explanations:
```shell
version: '3'    <----- To deploy a stack with a compose file the minimum version is '3'
services:
  todo:
    networks:
      - my_stack_network
    image: 'vmonte/todoexample:latest'    <------ simple DRF project (https://github.com/vamonte/toDoExample)
    environment:
      - POSTGRES_HOST=postgres
      - CORS_ORIGIN_WHITELIST=my-stack.vmonte.com
      - ALLOWED_HOSTS=my-stack.vmonte.com todo
    depends_on:
      - 'postgres'
    deploy:
        labels:
          - "traefik.port=8000"      <------- The default port of Træfɪk
          - "traefik.backend=todo"   <------- The backend name. used by Træfɪk for internal operations and for the web ui.
          - "traefik.frontend.rule=Host:my-stack.vmonte.com;PathPrefixStrip:/api"  <----- The rule to match this service. (here http://my-stack.vmonte.com/api/... will be redirect to the todo service)
    command: sh ./start.sh
  postgres:
    networks:
      - my_stack_network
    image: "postgres:9.6"
    environment:
      - POSTGRES_PASSWORD=todoer
      - POSTGRES_USER=todoer
      - POSTGRES_DB=todoer
    deploy:
      labels:
        - "traefik.enable=false"    <------ Træfɪk will ignore the postgres service when it will requests the running services to the swarm API
  containous/traefik:v1.1.2 \

networks:
  my_stack_network:
    external: true
```

#### To check the result :

```shell 
docker stack ls

# and

docker stack services my-stack
```

### Conclusion:

You have now a running swarm stack behind a Træfɪk proxy.

```shell
curl -X POST -H "host: my-stack.vmonte.com" -H "content-type: application/json" -d '{"title": "traefik test"}' http://localhost:80/api/todos/

curl -H "host: my-stack.vmonte.com" http://localhost:80/api/todos/

curl -H "host: my-stack.vmonte.com" http://localhost:80/api/todos/1/
```
