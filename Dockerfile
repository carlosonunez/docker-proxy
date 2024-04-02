# polipo seems to have been removed or not ported into Focal
FROM ubuntu:mantic AS base
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN apt -y update
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && printf UTC > /etc/timezone
RUN apt -y install software-properties-common dnsutils net-tools telnet traceroute smbclient ldap-utils tcpdump unzip wget curl

FROM base AS openconnect
ARG VPNC_SCRIPT_URL=https://gitlab.com/openconnect/vpnc-scripts/-/raw/master/vpnc-script
ARG OPENCONNECT_TROJANS_URL=https://gitlab.com/openconnect/openconnect/-/archive/master/openconnect-master.zip?path=trojans
RUN apt -y install openconnect
RUN mkdir -p /etc/vpnc && \
    curl -o /etc/vpnc/vpnc-script $VPNC_SCRIPT_URL && chmod 755 /etc/vpnc/vpnc-script
RUN mkdir /trojans && \
    wget -qO /tmp/trojans.zip $OPENCONNECT_TROJANS_URL && \
    unzip -j /tmp/trojans.zip -d /trojans

FROM openconnect AS openconnect-saml-support
RUN DEBIAN_FRONTEND=noninteractive apt -y install libc6 # This takes forever to install; installing it separately.
RUN apt -y install x11vnc xvfb gir1.2-gtk-3.0 gir1.2-webkit2-4.0
RUN apt -y install python3-pip python3-gi libcairo2-dev pkg-config python3-dev
RUN mkdir ~/.vnc
RUN pip3 install pycairo https://github.com/carlosonunez/gp-saml-gui/archive/master.zip --break-system-packages


FROM openconnect-saml-support AS proxies
ARG MICROSOCKS_GIT_URL=https://github.com/rofl0r/microsocks
RUN apt -y install git make autoconf libtool automake libssl-dev libgcrypt-dev \
    gnutls-dev pkg-config openssl
RUN git clone $MICROSOCKS_GIT_URL /tools/microsocks
RUN cd /tools/microsocks && make && make install
RUN apt -y install privoxy

FROM proxies AS openvpn
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
RUN apt -y install openvpn
RUN for script in network resolve; \
    do git clone https://github.com/alfredopalhares/openvpn-update-resolv-conf /tmp/systemd-$script && \
    mv /tmp/systemd-$script/update-systemd-$script.sh /etc/openvpn/update-systemd-$script.sh && \
    chmod 755 /etc/openvpn/update-systemd-$script.sh; \
    done

FROM openvpn AS common-finalconfigs
RUN apt -y install ca-certificates && update-ca-certificates

FROM common-finalconfigs AS app
RUN wget -O /usr/local/bin/test-globalprotect-login.py https://raw.githubusercontent.com/dlenski/gp-saml-gui/master/test-globalprotect-login.py
RUN chmod +x /usr/local/bin/test-globalprotect-login.py
RUN apt -y install sudo # gp-saml-gui requires sudo
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8118
EXPOSE 8889

ENTRYPOINT ["/entrypoint.sh"]
