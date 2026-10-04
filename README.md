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

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/whughesiii2187/darksaber:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/whughesiii2187/darksaber:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

For NVIDIA GPUs, use `darksaber-nvidia` in place of `darksaber` in both rebase commands. If Secure Boot is on, enroll Universal Blue's signing key for the NVIDIA kernel modules after the first reboot with `ujust enroll-secure-boot-key`.

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/how-to/generate-iso/#_top). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/whughesiii2187/darksaber
```
