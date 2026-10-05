#!/usr/bin/env bash
# Build an offline installer ISO with bootc-image-builder.
#
#   sudo ./iso/build-iso.sh                    # darksaber
#   sudo ./iso/build-iso.sh darksaber-nvidia   # NVIDIA variant
#
# The ISO and its checksum are written to ./output (or $OUTPUT_DIR).
#
# bootc-image-builder needs podman. Without podman, the script uses Docker
# to run itself inside a podman container. Set CONTAINER_ENGINE=docker or
# CONTAINER_ENGINE=podman to choose explicitly.
set -euo pipefail

image_name=${1:-darksaber}
image=ghcr.io/whughesiii2187/$image_name:latest
iso_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config=$iso_dir/$image_name.toml
output=${OUTPUT_DIR:-$PWD/output}

if [[ ! -f $config ]]; then
  echo "No installer config for $image_name: $config" >&2
  exit 1
fi

engine=${CONTAINER_ENGINE:-}
if [[ -z $engine ]]; then
  if command -v podman >/dev/null; then
    engine=podman
  elif command -v docker >/dev/null; then
    engine=docker
  else
    echo "Install podman or Docker to build the ISO." >&2
    exit 1
  fi
fi

case $engine in
  podman) ;;
  docker)
    mkdir -p "$output"
    exec docker run --rm --privileged \
      -v "$iso_dir:/iso:ro" \
      -v "$output:/output" \
      -e OUTPUT_DIR=/output \
      -e CONTAINER_ENGINE=podman \
      quay.io/podman/stable /iso/build-iso.sh "$image_name"
    ;;
  *)
    echo "Unsupported CONTAINER_ENGINE: $engine (use podman or docker)" >&2
    exit 1
    ;;
esac

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: bootc-image-builder needs rootful podman." >&2
  exit 1
fi

# bootc-image-builder reads the image from root's container storage.
podman pull "$image"

# The installer is built from the image's own repos, so it needs their keys.
rpm_gpg=$(mktemp -d)
trap 'rm -rf "$rpm_gpg"' EXIT
podman run --rm -v "$rpm_gpg:/out:Z" "$image" bash -c 'cp /etc/pki/rpm-gpg/* /out'

mkdir -p "$output"
podman run --rm --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v "$config:/config.toml:ro" \
  -v "$output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$rpm_gpg:/etc/pki/rpm-gpg:ro" \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type iso --rootfs btrfs --use-librepo=True \
  "$image"

mv "$output/bootiso/install.iso" "$output/$image_name.iso"
rmdir "$output/bootiso" 2>/dev/null || true
(cd "$output" && sha256sum "$image_name.iso" > "$image_name.iso-CHECKSUM")
echo "Wrote $output/$image_name.iso"
