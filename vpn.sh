#!/usr/bin/env bash
env_file_present() {
  test -f "$ENV_FILE"
}

env_file_hash() {
  echo "$ENV_FILE" | md5sum | cut -f1 -d '-' | head -c 8
}

openvpn_config_file() {
  echo "/tmp/openvpn-config.$(env_file_hash)"
}

openvpn_login_file() {
  echo "/tmp/openvpn-login.$(env_file_hash)"
}

create_openvpn_config_file_if_env_var_present() {
  if ! test -z "$OPENVPN_CONFIG_FILE"
  then
    cat "$OPENVPN_CONFIG_FILE" > "$(openvpn_config_file)"
  else
    echo "no openvpn config present" > "$(openvpn_config_file)"
  fi
}

create_openvpn_login_file() {
  printf "%s\n%s" "${OPENVPN_USERNAME:-none}" "${OPENVPN_PASSWORD:-none}" > "$(openvpn_login_file)"
}

delete_openvpn_login_and_config_file_if_present() {
  rm -f "$(openvpn_config_file)"
  rm -f "$(openvpn_login_file)"
}

ENV_FILE="${ENV_FILE:-$(dirname $0)/.env}"
if env_file_present
then
  export $(cat "$ENV_FILE" | grep -v "_OPTIONS" | xargs)
fi
VPN_CONTAINER_NAME="${VPN_CONTAINER_NAME:-vpn}"
VPN_DOCKER_IMAGE_NAME="${VPN_DOCKER_IMAGE_NAME:-local/docker_vpn}"
REBUILD_IMAGE="${REBUILD_IMAGE:-false}"
HTTP_PROXY_PORT="${HTTP_PROXY_PORT:-8118}"
SOCKS_PROXY_PORT="${SOCKS_PROXY_PORT:-8889}"

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
  cert_path=$(cat $ENV_FILE | grep OPENCONNECT_CERT_PATH | cut -f2 -d =)
  key_path=$(cat $ENV_FILE | grep OPENCONNECT_KEY_PATH | cut -f2 -d =)
  create_openvpn_config_file_if_env_var_present
  create_openvpn_login_file

  build_docker_image || return 1
  if test -z "$cert_path" || test -z "$key_path"
  then
    docker run --detach \
      --name "$VPN_CONTAINER_NAME" \
      --tty \
      --env-file "$ENV_FILE" \
      -v "$(openvpn_config_file):/etc/openvpn/openvpn.config" \
      -v "$(openvpn_login_file):/login_info" \
      --privileged \
      --publish $HTTP_PROXY_PORT:8118 \
      --publish $SOCKS_PROXY_PORT:8889 \
      --publish 1194:1194/udp \
      $VPN_DOCKER_IMAGE_NAME >/dev/null
  else
    docker run --detach \
      --name "$VPN_CONTAINER_NAME" \
      --tty \
      --env-file "$ENV_FILE" \
      -v $cert_path:/certificate \
      -v $key_path:/key \
      -v "$(openvpn_config_file):/etc/openvpn/openvpn.config" \
      -v "$(openvpn_login_file):/login_info" \
      --privileged \
      --publish $HTTP_PROXY_PORT:8118 \
      --publish $SOCKS_PROXY_PORT:8889 \
      --publish 1194:1194/udp \
      $VPN_DOCKER_IMAGE_NAME >/dev/null
  fi
}

stop_vpn() {
  if ! env_file_present
  then
    >&2 echo "ERROR: Please create a .env file (see README.md for instructions)."
    exit 1
  fi

  docker rm -f "$VPN_CONTAINER_NAME" 
  delete_openvpn_login_and_config_file_if_present
}
