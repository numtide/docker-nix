# This Docker uses the multi-stage build feature of Docker.
# It kicks of the installation of Nix in a temporary alpine container,
# after which we copy the installation to an empty image that only contains Nix.

FROM alpine:3.6 as FETCHER

ARG NIX_RELEASE=1.11.14

# Enable HTTPS support in wget.
RUN apk add --no-cache openssl

# Download Nix and install it into the system.
COPY ./install.sh ./install.sh
RUN ./install.sh

# Now create the actual image
FROM scratch
COPY --from=FETCHER /nix /nix
COPY --from=FETCHER /etc/passwd /etc/passwd
COPY --from=FETCHER /etc/shadow /etc/shadow
COPY --from=FETCHER /etc/group /etc/group

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
