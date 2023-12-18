# Solution

- [Solution](#solution)
  - [1. Requirements](#1-requirements)
  - [2. Create a .env file](#2-create-a-env-file)
  - [3. Local deployment (with docker)](#3-local-deployment-with-docker)
  - [4. kubernetes deployment (using local kind cluster)](#4-kubernetes-deployment-using-local-kind-cluster)
  - [5. Wipe out](#5-wipe-out)


## 1. Requirements

- Linux or MacOS operating systems
- `kind` k8s tool is installed
- `envsubst` command is installed
- `kubectl` command is installed
- `make` command is installed
- `curl` command is installed
- `base64` command is installed
- `jq` command is installed
- `docker` command is installed with buildx support
- a docker hub account with an access token created

## 2. Create a .env file

Create a `.env` file with the access token secret and username from docker hub:

```shell
DOCKER_HUB_ACCESS_CODE=<docker-hub-access-code>
DOCKER_HUB_USERNAME=<docker-hub-username>
DB_PASSWORD_BASE64=<your-database-password-in-base64-encoding>
```

For `DB_PASSWORD_BASE64`, use the value `dGVzdA==` for this lab. This is the password `test` in `base64` encoding. To convert a string to base64:
```shell
echo -n 'test' |base64
```

## 3. Local deployment (with docker)

Run the following to get the application running locally:

```shell
make up
```

Then, test if the application is running by executing `curl localhost:3000/posts` or just:

```shell
make test-docker
```

To stop the local containers, run the following command:

```shell
make down
```

This deployment will push a container image ([click here](https://hub.docker.com/r/rbrayner/life/tags)) to docker hub.

## 4. kubernetes deployment (using local kind cluster)

Run the following command to get the application running on kubernetes. A kind cluster will be created with a nginx controller.

```shell
make all-k8s version=<desired-app-version>
```

for `<desired-app-version>`, use any version you wish (e.g., 1.0, 2.0, etc.). It will build and push the image to docker hub, using both arm64 and amd64 platforms. 

To test if the application is running (exposed via an nginx ingress):

```shell
make test-k8s
```

`Instead`, if don't want to use the `all-k8s` make target, you could do it `step by step`:

```shell
make start-cluster
make build-and-push version=<desired-app-version>
make create-private-registry-secret
make deploy version=<desired-app-version>
```

To destroy the application resources (not the cluster):

```shell
make destroy
```


## 5. Wipe out

To stop the docker containers (local deployment) and wipe the kubernetes cluster, just run:

```shell
make wipe
```

