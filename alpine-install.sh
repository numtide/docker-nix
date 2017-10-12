#!/bin/sh
# Installs nix in archlinux
set -eux

wget -O- https://nixos.org/releases/nix/nix-$NIX_RELEASE/nix-$NIX_RELEASE-x86_64-linux.tar.bz2 | tar xjv

addgroup -g 30000 -S nixbld

for i in $(seq 1 30); do
    adduser -S -D -h /var/empty -g "Nix build user $i" -u $((30000 + i)) -G nixbld nixbld$i
done

mkdir -m 0755 /nix

USER=root sh nix-*-x86_64-linux/install
