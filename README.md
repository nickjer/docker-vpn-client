# Docker VPN Client

Docker image for [OpenConnect](http://www.infradead.org/openconnect/) that runs
an [SSH](https://www.openssh.com/) for easy SSH port forwarding.

## Build

```sh
git clone https://github.com/nickjer/docker-vpn-client.git
cd docker-vpn-client
docker build --force-rm -t nickjer/docker-vpn-client .
```

## Install

```sh
docker pull nickjer/docker-vpn-client
```

## Usage

First launch the docker container with the SSH server started and your SSH key
copied to the `root` account:

```sh
docker run --rm -i -t --privileged -p 4444:22 -e "SSH_KEY=$(cat ~/.ssh/id_rsa.pub)" nickjer/docker-vpn-client
```

Note that we mapped the host port `4444` to the container's port `22`.

From here you will be presented with a prompt, so that you can run the
`openconnect` client to connect to the VPN of your choosing:

```sh
openconnect <host>
```

### Using Username/Password

Open a new terminal and ssh to the Docker container:

```sh
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -p 4444 root@localhost
```

where we ignore the dynamic host SSH keys.

From within the container we ssh to the host behind the VPN:

```sh
ssh <username>@<host_behind_proxy>
```

and authenticate.

### Using Local SSH Key

Open a new terminal and setup port forwarding to the SSH host behind the VPN:

```sh
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -L 4445:<host_behind_vpn>:22 \
    -p 4444 root@localhost
```

where we forward the local port `4445` to the SSH host behind the VPN.

Now in **another terminal** you can connect to the SSH host behind the VPN:

```sh
ssh -p 4445 <user>@localhost
```

### SSH Config

To simplify connecting to the Docker container it is recommended you modify the
`~/.ssh/config` file as such:

```ssh
# ~/.ssh/config

Host vpn
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  User root
  Hostname localhost
  Port 4444
```

Then you can connect to the Docker container with:

```sh
ssh vpn
```

or for port forwarding:

```sh
ssh -L 4445:<host_behind_proxy>:22 vpn
```

### Wrapper Script

It is recommended to make a wrapper script around the Docker command to
simplify launching VPN clients. Create the script `~/bin/vpn-client` with:

```sh
#!/usr/bin/env bash

docker run \
  --rm \
  -i \
  -t \
  --privileged \
  -p ${SSH_PORT:-4444}:22 \
  -e "SSH_KEY=${SSH_KEY:-$(cat ~/.ssh/id_rsa.pub)}" \
  nickjer/docker-vpn-client
```

Followed by setting the permissions:

```sh
chmod 755 ~/bin/vpn-client
```

Then run:

```sh
vpn-client
```

### Juniper Network Connect

You can connect to a Juniper network with:

```sh
openconnect --juniper <vpn_host>
```

### Connect through Chrome

You can set up an SSH proxy with:

```sh
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -D 8080
    -p 4444 root@localhost
```

and connect to it with Chrome as:

```sh
google-chrome \
  --user-data-dir=$(mktemp -d) \
  --proxy-server="socks://localhost:8080" \
  --incognito
```
