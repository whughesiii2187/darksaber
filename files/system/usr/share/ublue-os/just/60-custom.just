# darksaber commands, run with `ujust <name>`

# Create the Fedora and Ubuntu dev boxes from /usr/share/darksaber/distrobox.ini
devbox:
    distrobox assemble create --file /usr/share/darksaber/distrobox.ini

# Set up Incus with default storage and networking (once per machine)
incus-init:
    incus admin init --minimal

# Install Kubernetes tools with Homebrew: kind, kubectl, helm, k9s
install-k8s-tools:
    /home/linuxbrew/.linuxbrew/bin/brew install kind kubernetes-cli helm k9s
    @echo "kind uses podman here: export KIND_EXPERIMENTAL_PROVIDER=podman before 'kind create cluster'"
