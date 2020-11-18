# polipo seems to have been removed or not ported into Focal
FROM ubuntu:18.04 
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG VPNC_SCRIPT_URL=http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
ARG MICROSOCKS_GIT_URL=https://github.com/rofl0r/microsocks
ARG OPENSHIFT_CLIENT_URL=https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-09-18-202631/openshift-client-linux-4.5.0-0.okd-2020-09-18-202631.tar.gz
ARG OPENCONNECT_TROJANS_URL=https://gitlab.com/openconnect/openconnect/-/archive/master/openconnect-master.zip?path=trojans

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


# Install latest version of microsocks
RUN apt -y install git make autoconf libtool automake curl libssl-dev libgcrypt-dev \
    gnutls-dev pkg-config openssl
RUN git clone $MICROSOCKS_GIT_URL /tools/microsocks
RUN cd /tools/microsocks && make && make install

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8889

# Some extra stuff I put down here to avoid rebuilding while testing.
RUN apt -y install dnsutils net-tools telnet traceroute smbclient ldap-utils tcpdump unzip wget

# Install OpenShift and kubectl clients
RUN wget -qO /tmp/openshift_client.tar.gz $OPENSHIFT_CLIENT_URL && \
    tar -xvf /tmp/openshift_client.tar.gz -C /usr/local/bin

# Install Privoxy and configure it to forward all HTTP/S traffic through SOCKS
RUN apt -y install privoxy

# Download CSD wrapper scripts that can help smooth over authentication issues.
RUN mkdir /trojans && \
    wget -qO /tmp/trojans.zip $OPENCONNECT_TROJANS_URL && \
    unzip -j /tmp/trojans.zip -d /trojans


ENTRYPOINT ["/entrypoint.sh"]
