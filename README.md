# Docker VPN Proxy
### Forward VPN traffic through an ultra-lightweight Docker container

**NOTE**: This is provided for educational purposes only. Please ensure that this is allowed
by your IT organization before using.

This image creates a Docker container that:

* Connects to your personal or corporate VPN through openconnect, and
* Creates a HTTP/HTTPS/SOCK proxy that browsers on your host can use to forward traffic through.

Inspired by [wazum/openconnect-proxy](https://github.com/wazum/openconnect-proxy) and
[matinrco/openconnect-proxy](https://github.com/matinrco/openconnect-proxy).

## Why?

Use this if you want to use VPN but don't want it taking over all traffic on your machine.

## Compatible with

- Cisco Anyconnect (if configured),
- GlobalProtect
- Juniper VPNs

## Not Compatible With

- Citrix Netscaler (not supported by openconnect)

## How do I use?

First, build this image: `docker build -t $IMAGE_NAME .`

Next, create an `.env` file containing the following:

```
	OPENCONNECT_URL=<Gateway URL>
	OPENCONNECT_USER=<Username>
	OPENCONNECT_PASSWORD=<Password>
	OPENCONNECT_OPTIONS=--authgroup <VPN Group> \
		--servercert <VPN Server Certificate> --protocol=<Protocol> \
		--reconnect-timeout 86400
```

_Don't use quotes around the values!_

Optionally set a multi factor authentication code:

	OPENCONNECT_MFA_CODE=<Multi factor authentication code>

See the [openconnect documentation](https://www.infradead.org/openconnect/manual.html) for available options. 

Next, create your container! `docker run --privileged --env-file .env -p 8888:8888 -p 8889:8889 $IMAGE_NAME`

Finally, configure your browser to use the proxy by setting its HTTP proxy to `localhost:8888`
and SOCKS proxy to `localhost:8889`.



