# polipo seems to have been removed or not ported into Focal
FROM ubuntu:latest AS base
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
RUN useradd -rm -d /home/docker -s /bin/bash -g root -G sudo -u 1000 docker
RUN mkdir /trojans && \
    wget -qO /tmp/trojans.zip $OPENCONNECT_TROJANS_URL && \
    unzip -j /tmp/trojans.zip -d /trojans


FROM openconnect AS proxies
ARG MICROSOCKS_GIT_URL=https://github.com/rofl0r/microsocks
RUN apt -y install git make autoconf libtool automake libssl-dev libgcrypt-dev \
    gnutls-dev pkg-config openssl
RUN git clone $MICROSOCKS_GIT_URL /tools/microsocks
RUN cd /tools/microsocks && make && make install
RUN apt -y install privoxy

FROM proxies AS openvpn
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
RUN apt -y install openvpn openresolv
RUN git clone https://github.com/alfredopalhares/openvpn-update-resolv-conf /tmp/resolv-conf && \
    mv /tmp/resolv-conf/update-resolv-conf.sh /etc/openvpn/update-resolv-conf.sh && \
    chmod 755 /etc/openvpn/update-resolv-conf.sh

FROM openvpn AS app
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8118
EXPOSE 8889

ENTRYPOINT ["/entrypoint.sh"]
