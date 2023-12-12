#!/bin/sh

source ./ormconfig.env
dockerize -wait tcp://${TYPEORM_HOST}:${TYPEORM_PORT} -timeout 60s && sleep 5
cd /app && yarn start