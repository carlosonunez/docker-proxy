# polipo seems to have been removed or not ported into Focal
FROM ubuntu:18.04 
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG VPNC_SCRIPT_URL=http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
ARG MICROSOCKS_GIT_URL=https://github.com/rofl0r/microsocks

# Configure tzdata (it's a dependency and a **** to configure)
RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && printf UTC > /etc/timezone


# Install OpenConnect
RUN apt -y update
RUN apt -y install software-properties-common
RUN add-apt-repository ppa:lopin/openconnect-globalprotect && apt -y install openconnect

# Install latest vpnc-script
RUN apt -y install curl
RUN mkdir -p /etc/vpnc && \
    curl -o /etc/vpnc/vpnc-script $VPNC_SCRIPT_URL && chmod 755 /etc/vpnc/vpnc-script

# Install polipo and ocproxy
RUN apt -y install polipo ocproxy


# Install latest version of microsocks
RUN apt -y install git make autoconf libtool automake curl libssl-dev libgcrypt-dev \
    gnutls-dev pkg-config openssl
RUN git clone $MICROSOCKS_GIT_URL /tools/microsocks
RUN cd /tools/microsocks && make && make install

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8888
EXPOSE 8889

ENTRYPOINT ["/entrypoint.sh"]
