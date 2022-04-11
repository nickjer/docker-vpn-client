# Docker VPN Client

Docker image for [OpenConnect](http://www.infradead.org/openconnect/) and
[OpenVPN](https://openvpn.net/) that runs an [SSH](https://www.openssh.com/)
server for easy SSH port forwarding and SOCKS proxying.

## Build with Docker

```sh
git clone https://github.com/nickjer/docker-vpn-client.git
cd docker-vpn-client
docker build --force-rm -t nickjer/docker-vpn-client .
```

## Install from Docker Hub

```sh
docker pull nickjer/docker-vpn-client
```

## Usage

The docker container is launched with the SSH server started and your SSH key
copied to the `root` account:

```sh
docker run \
  --rm \
  -i \
  -t \
  --privileged \
  --sysctl net.ipv6.conf.all.disable_ipv6=0 \
  -p 127.0.0.1:4444:22 \
  -e "SSH_KEY=$(cat ~/.ssh/id_rsa.pub)" \
  nickjer/docker-vpn-client
```

Note that we mapped the host port `4444` to the container's port `22`, but feel
free to change this.

From here you will be placed inside the container as `root` in a shell process.
You will then use whatever VPN client you are familiar with to connect to your
VPN server (may require logging in and two-factor authentication).

For example:

```sh
openconnect <host>
```

### SSH Tunnel Example (from container to remote server)

*Note: As your private SSH key does not reside in the container, this will only
work with remote SSH servers that you login with username/password.*

1. Open a new terminal and `ssh` to the Docker container:

   ```sh
   ssh -o UserKnownHostsFile=/dev/null \
       -o StrictHostKeyChecking=no \
       -p 4444 root@localhost
   ```

   where we ignore the dynamic host SSH keys.

2. From within the container we `ssh` to the host behind the VPN:

   ```sh
   ssh <username>@<host_behind_proxy>
   ```

   and authenticate.

### SSH Tunnel Example (through container to remote server)

*Note: This method is preferred if you login using SSH public keys.*

1. Open a new terminal and setup port forwarding to the SSH host behind the
   VPN:

   ```sh
   ssh -o UserKnownHostsFile=/dev/null \
       -o StrictHostKeyChecking=no \
       -L 4445:<host_behind_vpn>:22 \
       -p 4444 root@localhost
   ```

   where we forward the local port `4445` to the SSH host behind the VPN.

2. Now in **another terminal** you can connect to the SSH host behind the VPN:

   ```sh
   ssh -p 4445 <user>@localhost
   ```

## Examples

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

exec \
  docker run \
    --rm \
    --interactive \
    --tty \
    --privileged \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --publish "127.0.0.1:${SSH_PORT:-4444}:22" \
    --env "SSH_KEY=${SSH_KEY:-$(cat ~/.ssh/id_rsa.pub)}" \
    "${@}" \
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

### OpenVPN Connect

You will need to bind mount your client configuration file into the container
if you want to be able to connect to the VPN using it. For now lets use the
wrapper script we created above:

```sh
vpn-client -v "/path/to/client.ovpn:/client.ovpn"
```

Once inside the container we can connect to the VPN server using:

```sh
openvpn --config client.ovpn
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
