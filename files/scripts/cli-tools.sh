#!/usr/bin/env bash

# CLI tools that aren't in Fedora's repos. Release downloads are pinned and
# checksummed; bump the version and sha256 together.

set -oue pipefail

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fetch() { # url sha256 dest
  curl -fsSL --retry 3 -o "$3" "$1"
  echo "$2  $3" | sha256sum -c -
}

# lazygit (the atim/lazygit COPR has stopped updating)
LAZYGIT_VERSION=0.66.2
fetch "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" \
  158efc9ddfa1241fab5fb3526bb442c8dc6c4b1904d73213b9e4e93e03c52034 "$WORK/lazygit.tar.gz"
tar -xzf "$WORK/lazygit.tar.gz" -C "$WORK" lazygit
install -Dm0755 "$WORK/lazygit" /usr/bin/lazygit

# Clipboard (cb). It loads its Wayland/X11 plugins from next to the binary
# ($ORIGIN), so the binary and libs stay together and /usr/bin gets a link.
CLIPBOARD_VERSION=0.10.0
fetch "https://github.com/Slackadays/Clipboard/releases/download/${CLIPBOARD_VERSION}/clipboard-linux-amd64.zip" \
  23a654c05aee16a0945eb933d5466122c38bdbc9aa39f6dd168d25bf51591441 "$WORK/clipboard.zip"
unzip -q "$WORK/clipboard.zip" -d "$WORK/clipboard"
install -Dm0755 "$WORK/clipboard/bin/cb" /usr/libexec/clipboard/cb
install -m0755 "$WORK/clipboard/lib/libcbwayland.so" "$WORK/clipboard/lib/libcbx11.so" /usr/libexec/clipboard/
ln -sf ../libexec/clipboard/cb /usr/bin/cb

# 0xProto Nerd Font
NERDFONTS_VERSION=3.5.1
fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NERDFONTS_VERSION}/0xProto.tar.xz" \
  3f2d36e4fa8b3af2f97b14b57c5b0f57f4c1bda5a59533fb913a9ff3344db7ce "$WORK/0xProto.tar.xz"
mkdir -p /usr/share/fonts/0xproto-nerd-fonts
tar -xJf "$WORK/0xProto.tar.xz" -C /usr/share/fonts/0xproto-nerd-fonts --wildcards '*.ttf'
fc-cache -f /usr/share/fonts/0xproto-nerd-fonts

# Claude Code and the devcontainer CLI, from npm. --prefix /usr: npm's
# default /usr/local is /var/usrlocal on Atomic, which isn't in the image.
# Both stay current through the daily image builds.
export npm_config_cache="$WORK/npm-cache"
npm install -g --prefix /usr @anthropic-ai/claude-code @devcontainers/cli

# Fail the build early if any of them is missing
lazygit --version
cb help >/dev/null # cb has no --version
claude --version
devcontainer --version
test -n "$(fc-list '0xProto Nerd Font')"
