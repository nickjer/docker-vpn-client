FROM alpine:latest
LABEL maintainer="Jeremy Nicklas"

# Set language to avoid bugs that sometimes appear
ENV LANG en_US.UTF-8

# Set up requirements
RUN echo "root:root" | chpasswd \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --no-cache \
      openconnect \
      openvpn \
      openssh \
    && mkdir ${HOME}/.ssh

CMD ["sh", "-c", "echo \"${SSH_KEY}\" > ~/.ssh/authorized_keys && ssh-keygen -A && /usr/sbin/sshd && sh"]
