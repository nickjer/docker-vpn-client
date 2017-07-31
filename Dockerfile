FROM alpine:latest
LABEL maintainer="Jeremy Nicklas"

# Set language to avoid bugs that sometimes appear
ENV LANG en_US.UTF-8

# Set up requirements
RUN apk add --no-cache \
      libxml2 \
      openssl \
      openssh \
    && mkdir ${HOME}/.ssh

ENV OPENCONNECT_VERSION 7.08

# Build openconnect
RUN apk add --no-cache --virtual .openconnect-build-deps \
      build-base \
      libxml2-dev \
      zlib-dev \
      openssl-dev \
      pkgconfig \
      gettext \
      linux-headers \
    && mkdir -p /etc/vpnc \
    && wget -O /etc/vpnc/vpnc-script "http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script" \
    && chmod 755 /etc/vpnc/vpnc-script \
    && wget -O openconnect.tar.gz "ftp://ftp.infradead.org/pub/openconnect/openconnect-${OPENCONNECT_VERSION}.tar.gz" \
    && mkdir -p /tmp/openconnect \
    && tar -C /tmp/openconnect --strip-components=1 -xzf openconnect.tar.gz \
    && rm openconnect.tar.gz \
    && cd /tmp/openconnect \
    && ./configure \
    && make \
    && make install \
    && cd / \
    && rm -fr /tmp/openconnect \
    && apk del .openconnect-build-deps

CMD ["sh", "-c", "echo \"${SSH_KEY}\" > ~/.ssh/authorized_keys && ssh-keygen -A && /usr/sbin/sshd && sh"]
