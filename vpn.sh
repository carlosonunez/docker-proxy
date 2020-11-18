#!/usr/bin/env bash
ENV_FILE="${ENV_FILE:-$(dirname $0)/.env}"
VPN_CONTAINER_NAME="${VPN_CONTAINER_NAME:-vpn}"
VPN_DOCKER_IMAGE_NAME="${VPN_DOCKER_IMAGE_NAME:-local/docker_vpn}"
REBUILD_IMAGE="${REBUILD_IMAGE:-false}"

env_file_present() {
  test -f "$ENV_FILE"
}

build_docker_image() {
  if ! docker images | grep -q "$VPN_DOCKER_IMAGE_NAME" || test "$REBUILD_IMAGE" != "false"
  then
    docker build -t "$VPN_DOCKER_IMAGE_NAME" -f $(dirname $0)/Dockerfile $(dirname $0)
  fi
}

start_vpn() {
  if ! env_file_present
  then
    >&2 echo "ERROR: Env file missing at $ENV_FILE (see README.md to learn how to create one)."
    exit 1
  fi

  build_docker_image && 
    docker run --detach \
      --name "$VPN_CONTAINER_NAME" \
      --tty \
      --env-file "$ENV_FILE" \
      --privileged \
      --publish 8118:8118 \
      --publish 8889:8889 \
      $VPN_DOCKER_IMAGE_NAME >/dev/null
}

stop_vpn() {
  if ! env_file_present
  then
    >&2 echo "ERROR: Please create a .env file (see README.md for instructions)."
    exit 1
  fi

  docker rm -f "$VPN_CONTAINER_NAME" 
}
