#!/usr/bin/env bash

docker network create --opt encrypted --driver overlay --subnet 192.168.100.0/24  my_stack_network
