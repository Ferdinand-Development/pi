#!/bin/bash

docker-compose -f ${PWD}/docker-compose.yaml up -d
docker-compose -f ${PWD}/docker-compose.yaml pull
docker-compose -f ${PWD}/docker-compose.yaml up -d
