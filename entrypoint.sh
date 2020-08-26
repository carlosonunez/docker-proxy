#!/bin/bash

if [[ (-n "${PROXY_USERNAME:-}") && (-n "${PROXY_PASSWORD:-}")  ]]; then
    echo "Setting up polipo with authentication ..."
    polipo proxyAddress=0.0.0.0 proxyPort=8888 socksParentProxy=localhost:11080 authCredentials=${PROXY_USERNAME}:${PROXY_PASSWORD} &
else
    echo "Setting up polipo without authentication ..."
    polipo proxyAddress=0.0.0.0 proxyPort=8888 socksParentProxy=localhost:11080 &
fi

/usr/local/bin/microsocks -i 0.0.0.0 -p 8889 & 

run () {
  # Start openconnect
  if [[ -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Ask for password
    openconnect --script-tun --script "ocproxy -D 11080" -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]] && [[ ! -z "${OPENCONNECT_MFA_CODE}" ]]; then
  # Multi factor authentication (MFA)
    (echo $OPENCONNECT_PASSWORD; echo $OPENCONNECT_MFA_CODE) | openconnect --script-tun --script "ocproxy -D 11080" -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Standard authentication
    echo $OPENCONNECT_PASSWORD | openconnect --script-tun --script "ocproxy -D 11080" -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  fi
}

until (run); do
  echo "openconnect exited. Restarting process in 60 seconds…" >&2
  sleep 60
done

