#!/bin/bash

/usr/local/bin/microsocks -i 0.0.0.0 -p 8889 & 
cat >/etc/privoxy/config <<-PRIVOXY_CONFIG
listen-address          0.0.0.0:8118
forward-socks5          /             127.0.0.1:8889    .
PRIVOXY_CONFIG
privoxy /etc/privoxy/config &

run_openconnect () {
  set -x
  # Start openconnect
  options="$OPENCONNECT_OPTIONS"
  if test -f /certificate && test -f /key
  then
    options="$options -c /certificate -k /key"
  fi
  if [[ -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Ask for password
    openconnect -u $OPENCONNECT_USER $options $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]] && [[ ! -z "${OPENCONNECT_MFA_CODE}" ]]; then
  # Multi factor authentication (MFA)
    (echo $OPENCONNECT_PASSWORD; echo $OPENCONNECT_MFA_CODE) | openconnect -u $OPENCONNECT_USER $options --passwd-on-stdin $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Standard authentication
    echo $OPENCONNECT_PASSWORD | openconnect -u $OPENCONNECT_USER $options --passwd-on-stdin $OPENCONNECT_URL
  fi
  set +x
}

run_openvpn() {
  openvpn --config /etc/openvpn/openvpn.config
}

if test "$(cat /etc/openvpn/openvpn.config)" != "no openvpn config present"
then
  until (run_openvpn); do
    echo "openvpn exited; restarting in 60 seconds..." >&2
    sleep 60
  done
else
  until (run_openconnect); do
    echo "openconnect exited. Restarting process in 60 seconds…" >&2
    sleep 60
  done
fi

