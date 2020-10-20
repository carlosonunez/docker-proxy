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

First, create an `.env` file containing the following:

```
	OPENCONNECT_URL=<Gateway URL>
	OPENCONNECT_USER=<Username>
	OPENCONNECT_PASSWORD=<Password>
	OPENCONNECT_OPTIONS=--authgroup <VPN Group> \
		--servercert <VPN Server Certificate> --protocol=<Protocol> \
		--reconnect-timeout 86400
```

An update to date example is provided at `.env.example`.

_Don't use quotes around the values!_

Optionally set a multi factor authentication code:

	OPENCONNECT_MFA_CODE=<Multi factor authentication code>

See the [openconnect documentation](https://www.infradead.org/openconnect/manual.html) for available options. 

Next, start the VPN: `./start_vpn.sh`. You will not see any output if successful.

Finally, configure your browser to use the proxy by setting its HTTP proxy to `localhost:8118`
and SOCKS proxy to `localhost:8889`.

To stop the VPN, simply run: `./stop_vpn.sh`.

## Troubleshooting

### My connection is really slow. How can I fix it?

Most VPN slowness can be resolved by restarting the VPN container. Run this to do that:
`./restart_vpn.sh`.
