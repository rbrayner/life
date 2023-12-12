FROM node:alpine3.18

ENV DOCKERIZE_VERSION v0.7.0

RUN apk update --no-cache \
    && apk add --no-cache wget openssl \
    && wget -O - https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz | tar xzf - -C /usr/local/bin \
    && apk del wget

RUN apk add curl

WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
RUN chmod +x /app/entrypoint.sh
EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
