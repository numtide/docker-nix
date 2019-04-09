# This Docker uses the multi-stage build feature of Docker.
# It kicks of the installation of Nix in a temporary alpine container,
# after which we copy the installation to an empty image that only contains Nix.

FROM alpine:3.8 as FETCHER

# Enable HTTPS support in wget.
RUN apk add --no-cache openssl ca-certificates

# Install it in busybox for a start
COPY ./version.env ./version.env
COPY ./alpine-install.sh ./alpine-install.sh
RUN ./alpine-install.sh

ENV PATH=/nix/var/nix/profiles/default/bin:/usr/bin:/bin

# Give us a basic environment
RUN nix-channel --add \
  https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
  nix-channel --update

RUN nix-env -iA \
  nixpkgs.bashInteractive \
  nixpkgs.cacert \
  nixpkgs.coreutils \
  nixpkgs.gitMinimal \
  nixpkgs.gnutar \
  nixpkgs.gzip \
  nixpkgs.iana-etc \
  nixpkgs.xz \
  && true

# Remove old things
RUN \
  nix-channel --remove nixpkgs && \
  rm -rf /nix/store/*-nixpkgs* && \
  nix-collect-garbage -d

# Fixes missing hashes
RUN nix-store --verify --check-contents

# Fixes root login shell
RUN sed -e "s|/bin/ash|/bin/bash|g" -i /etc/passwd

# Now create the actual image
FROM scratch
COPY --from=FETCHER /etc/group /etc/group
COPY --from=FETCHER /etc/passwd /etc/passwd
COPY --from=FETCHER /etc/shadow /etc/shadow
COPY --from=FETCHER /nix /nix
COPY --from=FETCHER /root /root

RUN ["/nix/var/nix/profiles/default/bin/ln", "-s", "/nix/var/nix/profiles/default/bin", "/bin"]

RUN \
  mkdir -p /usr/bin && \
  ln -s /nix/var/nix/profiles/default/etc/ssl /etc/ssl && \
  ln -s /nix/var/nix/profiles/default/etc/protocols /etc/protocols && \
  ln -s /nix/var/nix/profiles/default/etc/services /etc/services && \
  ln -s /nix/var/nix/profiles/default/bin/env /usr/bin/env && \
  mkdir --mode=1777 /tmp

ENV \
    ENV=/nix/var/nix/profiles/default/etc/profile.d/nix.sh \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin \
    PAGER=cat \
    GIT_SSL_CAINFO=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels

# The sandbox requires privileged docker containers
RUN mkdir -p /etc/nix && echo sandbox = false > /etc/nix/nix.conf

CMD "bash"
