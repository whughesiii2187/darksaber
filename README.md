# darksaber &nbsp; [![bluebuild build badge](https://github.com/whughesiii2187/darksaber/actions/workflows/build.yml/badge.svg)](https://github.com/whughesiii2187/darksaber/actions/workflows/build.yml)

A Fedora Atomic image for containerized development, built with [BlueBuild](https://blue-build.org), using the [Niri](https://github.com/YaLTeR/niri) scrolling compositor and [DankMaterialShell](https://danklinux.com) as the desktop. Inspired by [Zirconium](https://github.com/zirconium-dev/zirconium).

| Image | For |
|---|---|
| `ghcr.io/whughesiii2187/darksaber` | Intel and AMD graphics |
| `ghcr.io/whughesiii2187/darksaber-nvidia` | NVIDIA GTX 16xx / RTX and newer (open kernel modules, GPU access in containers) |

- **Base:** `ghcr.io/ublue-os/base-main` / `base-nvidia` (Fedora Atomic + codecs/firmware, no desktop environment)
- **Desktop:** Niri, DankMaterialShell, `dms-greeter` on greetd, Ghostty, Nautilus
- **Apps:** Firefox, LibreOffice, Bazaar, Flatseal, Gear Lever, Podman Desktop and a few GNOME utilities as Flatpaks; VS Code; imv and mpv for images and video.
- **System:** ufw as the firewall, Homebrew for the first user, zsh available as a login shell.

## Development workflow

The host stays clean: compilers and language runtimes live in containers, CLI tools come from Homebrew, and GUI apps from Flatpak.

- **Containers:** rootless Podman with `podman-compose`, `buildah`, `skopeo` and `podman-tui`. `docker` is Podman, and `DOCKER_HOST` points at the Podman socket, so devcontainers, VS Code Dev Containers, Testcontainers and `act` work without Docker.
- **Dev boxes:** `ujust devbox` creates `fedora-dev` and `ubuntu-dev` distroboxes with build tools (defined in `/usr/share/darksaber/distrobox.ini`).
- **System containers and VMs:** Incus (`ujust incus-init` once) and QEMU/KVM with virt-manager. Admins are added to the `incus-admin` and `libvirt` groups on boot.
- **Kubernetes:** `ujust install-k8s-tools` installs kind, kubectl, helm and k9s with Homebrew.
- **Git:** `git-lfs`, and HTTPS logins are stored in the keyring.
- **Limits:** higher inotify and open-file limits for IDEs, language servers and file watchers.

> [!NOTE]
> Rootless containers (the default) are covered by ufw. **Rootful** Podman containers with published ports write their own firewall rules, so those ports can be reachable from your network even when ufw would block them. Rootful containers on a custom network also need a ufw rule for DNS on that network's bridge.

## Customizing Niri

On first login, `~/.config/niri/config.kdl` is created. It includes the system defaults from `/usr/share/darksaber/niri/darksaber.kdl` (updated with the image), DMS's generated `dms/*.kdl` files, and then `local.kdl`.

Put your own tweaks in `~/.config/niri/local.kdl` (per user) or `/etc/niri/local.kdl` (system-wide). Because they're included last, later binds override the defaults.

## Installation

Pick the image for your GPU:

- Intel / AMD: `ghcr.io/whughesiii2187/darksaber`
- NVIDIA: `ghcr.io/whughesiii2187/darksaber-nvidia`

### Fresh install

Build an installer ISO (see [ISO](#iso) below) and install from it. The image's signing key comes with it, so there's nothing else to set up.

### Switching from another Fedora Atomic system (one time)

Only needed when moving an existing Silverblue, Kinoite, Bluefin, etc. install onto darksaber:

```bash
sudo bootc switch ghcr.io/whughesiii2187/darksaber:latest
systemctl reboot
# darksaber's signing key and policy are now installed; start enforcing them:
sudo bootc switch --enforce-container-sigpolicy ghcr.io/whughesiii2187/darksaber:latest
systemctl reboot
```

For NVIDIA, use `darksaber-nvidia` in both commands. If Secure Boot is on, enroll Universal Blue's key for the NVIDIA kernel modules after the first reboot with `ujust enroll-secure-boot-key`.

### Updating

Once you're on darksaber, none of the steps above are needed again. Updates download in the background and apply on the next reboot. To update by hand:

```bash
sudo bootc upgrade   # then reboot
sudo bootc status    # which image you're on and whether its signature is enforced
sudo bootc rollback  # boot the previous image if an update causes problems
```

`latest` follows the base image's latest Fedora release, so new Fedora versions arrive as normal updates. To stay on a release, pin `image-version` in `recipes/recipe.yml` (for example `44`).

## ISO

You can generate an offline installer ISO with [bootc-image-builder](https://github.com/osbuild/bootc-image-builder) on any machine with podman or Docker:

```bash
sudo ./iso/build-iso.sh                    # writes output/darksaber.iso
sudo ./iso/build-iso.sh darksaber-nvidia   # writes output/darksaber-nvidia.iso
```

bootc-image-builder needs rootful podman. If podman isn't installed, the script uses Docker to run itself inside a podman container, so you don't need `sudo` if your user is in the `docker` group. To pick one when both are installed, set `CONTAINER_ENGINE=podman` or `CONTAINER_ENGINE=docker`.

The installer's settings are in `iso/<image>.toml`. You create your user account in the installer, and the automatic disk layout is Btrfs using the whole disk. After installing, the system updates from the signed image on `ghcr.io`.

The ISO doesn't enroll a Secure Boot key, so there's no MOK enrollment screen on first boot. If you use `darksaber-nvidia` with Secure Boot on, the NVIDIA kernel modules won't load until you enroll Universal Blue's key with `ujust enroll-secure-boot-key` (or turn Secure Boot off).

These ISOs are too large to distribute on GitHub for free, so if you share the image publicly, host the ISO somewhere else.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/whughesiii2187/darksaber
```
