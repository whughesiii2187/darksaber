#!/usr/bin/env bash

set -oue pipefail

# Boot into the graphical target so greetd starts
systemctl set-default graphical.target

# Unlock gnome-keyring with the login password. Newer greetd packages ship
# the PAM file in /usr/lib/pam.d instead of /etc/pam.d
greetd_pam=/etc/pam.d/greetd
[ -f "$greetd_pam" ] || greetd_pam=/usr/lib/pam.d/greetd
sed -i -e '/pam_gnome_keyring.so/ s/^-auth/auth/' \
       -e '/pam_gnome_keyring.so/ s/^-session/session/' "$greetd_pam"
# Fail the build if the PAM file changed and the sed above didn't apply
grep -qE '^auth\s+.*pam_gnome_keyring\.so' "$greetd_pam"
grep -qE '^session\s+.*pam_gnome_keyring\.so' "$greetd_pam"

# Fail the build early if the core pieces are missing
niri --version
command -v dms dms-greeter quickshell xwayland-satellite ghostty
test -f /usr/lib/systemd/user/dms.service
test -f /usr/lib/systemd/user/dsearch.service
command -v dfiles
test -f /usr/lib/systemd/user/dfiles.service
test -f /usr/share/xdg-desktop-portal/portals/dfiles.portal
test -f /usr/share/applications/dev.duxlabs.files.desktop

# ufw replaces firewalld; don't let both manage the firewall
systemctl mask firewalld.service

# Allow forwarded traffic so libvirt's NAT network works behind ufw
sed -i 's/^DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
grep -q '^DEFAULT_FORWARD_POLICY="ACCEPT"' /etc/default/ufw

# ufw keeps its rules in /var/lib/ufw, which an installed system doesn't get
# from the image; save the defaults for tmpfiles.d/darksaber-var.conf to copy
mkdir -p /usr/share/darksaber
cp -a /var/lib/ufw /usr/share/darksaber/ufw
test -f /usr/share/darksaber/ufw/user.rules
test -f /usr/share/darksaber/ufw/user6.rules

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

# New users (including the one made in the installer) log in to zsh
sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd
grep -qx 'SHELL=/usr/bin/zsh' /etc/default/useradd
grep -qx '/usr/bin/zsh' /etc/shells

# Fedora 45+ ships its repo files in /usr/share/dnf5/repos.d, but
# bootc-image-builder only reads /etc/yum.repos.d when building the ISO.
# Copy them over; dnf5 treats a same-named file in /etc as an override, so
# this changes nothing for dnf itself
for repo in /usr/share/dnf5/repos.d/*.repo; do
  [ -e "/etc/yum.repos.d/${repo##*/}" ] || cp "$repo" /etc/yum.repos.d/
done
test -f /etc/yum.repos.d/fedora.repo

# Fail the build early if the CLI tools are missing
command -v stow tmux nvim rg bat tree-sitter gcc fzf
