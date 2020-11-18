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

An update to date example is provided at `.env.example`. _Don't use quotes around the values!_

Optionally set a multi factor authentication code:

	OPENCONNECT_MFA_CODE=<Multi factor authentication code>

See the [openconnect documentation](https://www.infradead.org/openconnect/manual.html) for available options. 

Next, start the VPN: `./start_vpn.sh`. You will not see any output if successful.

**NOTE**: If your `.env` file is not in your current working directory, use this instead:
`ENV_FILE=/path/to/env ./start_vpn.sh`

Finally, configure your browser to use the proxy by setting its HTTP proxy to `localhost:8118`
and SOCKS proxy to `localhost:8889`.

To stop the VPN, simply run: `./stop_vpn.sh`.

**NOTE**: If your `.env` file is not in your current working directory, use this instead:
`ENV_FILE=/path/to/env ./stop_vpn.sh`

## Cool Use Cases

### Dedicated browser for separating normal web browsing from "protected" web browsing

[Create a separate Firefox profile](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Multiple_profiles).
Configure its HTTP proxy to `localhost:8118`, its SOCKS5 proxy to `localhost:8443` and enable
"Proxy DNS request through SOCKS". Boom! You now have a dedicated web browser that goes through
the proxy.

### Execute shell requests through the proxy

If you need to access a resource through the proxy, simply export these environment variables:

```sh
export HTTP_PROXY=localhost:8118
export HTTPS_PROXY=localhost:8118
export SOCKS_PROXY=localhost:8889
```

or you can put them before your command to use them for one-off processes:

```sh
HTTP_PROXY=localhost:8118 HTTPS_PROXY=localhost:8118 SOCKS_PROXY=localhost:8889 curl [options]
```

## Troubleshooting

### My connection is really slow. How can I fix it?

Most VPN slowness can be resolved by restarting the VPN container. Run this to do that:
`./restart_vpn.sh`.

**NOTE**: If your `.env` file is not in your current working directory, use this instead:
`ENV_FILE=/path/to/env ./restart_vpn.sh`

### I need to use a csd-wrapper script to connect to my VPN. How can I do that?

This Docker image downloads the Openconnect "trojan" scripts into the `/trojans` directory.
If you need to use one (like `hipreport.sh` for GlobalProtect VPNs), add
`--csd-wrapper=/trojans/hipreport.sh` to the `OPENCONNECT_OPTIONS` environment variable.
