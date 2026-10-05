#!/usr/bin/env bash

set -oue pipefail

# Boot into the graphical target so greetd starts
systemctl set-default graphical.target

# Unlock gnome-keyring with the login password
sed -i -e '/pam_gnome_keyring.so/ s/^-auth/auth/' \
       -e '/pam_gnome_keyring.so/ s/^-session/session/' /etc/pam.d/greetd

# Fail the build early if the core pieces are missing
niri --version
command -v dms dms-greeter quickshell xwayland-satellite ghostty
test -f /usr/lib/systemd/user/dms.service
test -f /usr/lib/systemd/user/dsearch.service

# ufw replaces firewalld; don't let both manage the firewall
systemctl mask firewalld.service

# Allow forwarded traffic so libvirt's NAT network works behind ufw
sed -i 's/^DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
grep -q '^DEFAULT_FORWARD_POLICY="ACCEPT"' /etc/default/ufw

# Register git-lfs filters system-wide (appends to /etc/gitconfig)
git lfs install --system

# Fail the build early if the dev tooling is missing
command -v docker podman-compose buildah skopeo incus code
test -f /usr/lib/systemd/user/podman.socket

# darksaber's `ujust` commands live in 60-custom.just; make sure the base
# image's ujust still imports it
grep -qF '60-custom.just' /usr/share/ublue-os/justfile

# The base image deletes /usr/bin/chsh even though util-linux is installed;
# reinstall the package to put it back
dnf -y reinstall util-linux
command -v chsh
