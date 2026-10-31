# darksaber commands, run with `ujust <name>`

# Create the Fedora and Ubuntu dev boxes from /usr/share/darksaber/distrobox.ini
devbox:
    distrobox assemble create --file /usr/share/darksaber/distrobox.ini

# Set up Incus with default storage and networking (once per machine)
incus-init:
    incus admin init --minimal
