# This Docker uses the multi-stage build feature of Docker.
# It kicks of the installation of Nix in a temporary alpine container,
# after which we copy the installation to an empty image that only contains Nix.

FROM alpine:3.6 as FETCHER

# Enable HTTPS support in wget.
RUN apk add --no-cache openssl

# Select which nix release to install
ARG NIX_RELEASE=1.11.14

# Download Nix and install it into the system.
ADD https://nixos.org/releases/nix/nix-$NIX_RELEASE/nix-$NIX_RELEASE-x86_64-linux.tar.bz2 /nix.tar.bz2

# Install it in busybox for a start
COPY ./alpine-install.sh ./alpine-install.sh
RUN ./alpine-install.sh /nix.tar.bz2

# FIXME: Give us a shell
RUN nix-env -iA nixpkgs.bash

# Now create the actual image
FROM scratch
COPY --from=FETCHER /nix /nix
COPY --from=FETCHER /etc/passwd /etc/passwd
COPY --from=FETCHER /etc/shadow /etc/shadow
COPY --from=FETCHER /etc/group /etc/group

RUN ["/nix/var/nix/profiles/default/bin/bash", "-c", "ln -s /nix/var/nix/profiles/default/bin /bin"]
RUN \
  mkdir -p /usr/bin && \
  ln -s /nix/var/nix/profiles/default/bin/env /usr/bin/env

ONBUILD ENV \
    ENV=/nix/var/nix/profiles/default/etc/profile.d/nix.sh \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt

ENV \
    ENV=/nix/var/nix/profiles/default/etc/profile.d/nix.sh \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels
