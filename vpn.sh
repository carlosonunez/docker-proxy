#!/usr/bin/env bash
VPN_CONTAINER_NAME="${VPN_CONTAINER_NAME:-vpn}"
VPN_DOCKER_IMAGE_NAME="${VPN_DOCKER_IMAGE_NAME:-local/docker_vpn}"
REBUILD_IMAGE="${REBUILD_IMAGE:-false}"

env_file_present() {
  test -f "$(dirname $0)/.env"
}

build_docker_image() {
  if ! docker images | grep -q "$VPN_DOCKER_IMAGE_NAME" || test "$REBUILD_IMAGE" != "false"
  then
    docker build -t "$VPN_DOCKER_IMAGE_NAME" \
      -f $(dirname $0)/include/dockerfiles/openconnect-vpn/Dockerfile \
      $(dirname $0)/include/dockerfiles/openconnect-vpn
  fi
}

start_vpn() {
  if ! env_file_present
  then
    >&2 echo "ERROR: Please create a .env file (see README.md for instructions)."
    exit 1
  fi

  build_docker_image && 
    docker run --detach \
      --name "$VPN_CONTAINER_NAME" \
      --tty \
      --env-file "$(dirname $0)/.env" \
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

  docker rm -f "$VPN_CONTAINER_NAME" -q
}
