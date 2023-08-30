Working around issues and wrapping Citrix Workplace App for Linux.


# Problem

- HdxEngine does not work if wayland .so are available (Teams optimization) → (Coredump when stopping screensharing)
- Wrap Citrix into it's own namespace (limit access to folders and devices)

# Dependencies

- Bubblewrap / bwrap (https://github.com/containers/bubblewrap)
- podman or buildah (building the image)
- just build tool (https://github.com/casey/just)

# Limitations

- No hotplug of video devices (webcam)

# Solution

- Installation of [Citrix Workspace App](https://docs.citrix.com/en-us/citrix-workspace-app-for-linux/whats-new.html) into a container
- Export the Container into a root filesystem
- Use [bwrap](https://github.com/containers/bubblewrap) to simulate a new root filesystem

Most of the time I use the weblogin and start `wfica` just to present the desktop. It is also possible to use `selfservice` login.

# My use case

It works for my use case. Using weblogin and starting the virtual desktop, using MS Teams with optimization, screensharing and webcam.

I mainly use it on [NixOS](https://nixos.org).

I haven't tested smartcard login or USB redirection.

# Installation

1. Install podman to create the container (`just build`)
1. Unpack to RUNPATH (`just installforbwrap`)
3. Create `wfica.sh`. After that it is possible to run `./wfica.sh`, which will start `selfservice`, if an argument is added it starts `wfica` with that argument (see: `run.sh` in the container).

```
#/usr/bin/env bash
set -euo pipefail
IMAGE="localhost/citrix:latest"
RUNPATH=${HOME}/.var/bwrap/citrixroot

if [[ ! -d $RUNPATH ]]; then
  mkdir -p $RUNPATH && podman export $(podman create $IMAGE) | tar -C $RUNPATH -xf -
fi

[[ ! -d $HOME/.ICAClient ]] && mkdir $HOME/.ICAClient
[[ ! -f $HOME/.ICAClient/clientlicense ]] && touch $HOME/.ICAClient/clientlicense

config.json \
(exec bwrap \
  --bind $RUNPATH / \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /var/log \
  --dir /var \
  --bind-try $HOME/.ICAClient/clientlicense /etc/icalicense/clientlicense \
  --tmpfs $HOME \
  --bind $HOME/.ICAClient $HOME/.ICAClient \
  --bind-try "${@: -1}" "$(realpath "${@: -1}")" \
  --tmpfs $HOME/.ICAClient/logs \
  --clearenv \
  --setenv PS1 "citrix$ " \
  --hostname "wxdvdi005988" \
  --setenv PATH "/bin:/usr/bin:/usr/local/bin" \
  --ro-bind $XAUTHORITY $HOME/.Xauthority \
  --setenv XDG_DATA_DIRS "/opt/kde/share:/usr/local/share:/usr/share" \
  --dir "$XDG_RUNTIME_DIR" \
  --ro-bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
  --ro-bind "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse" \
  --dev-bind /dev/snd /dev/snd \
  --setenv ALSA_CARD $(aplay -l | awk -F \: '/,/{print $2}' | awk '{print $1}' | uniq | head -1) \
  --setenv XDG_RUNTIME_DIR $XDG_RUNTIME_DIR \
  --ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0 \
  --setenv DISPLAY "$DISPLAY" \
  --setenv TZ "Europe/Zurich" \
  --setenv HOME "$HOME" \
  --setenv LANG "en_US.UTF-8" \
  --setenv LIBVA_DRIVER_NAME "iHD" \
  --ro-bind /sys/devices /sys/devices \
  --ro-bind-try /sys/class/power_supply /sys/class/power_supply \
  --ro-bind "$XDG_RUNTIME_DIR/at-spi/bus" "$XDG_RUNTIME_DIR/at-spi/bus" \
  --setenv LD_PRELOAD "/usr/local/lib/XlibNoSHM.so" \
  --dev-bind-try /dev/dri /dev/dri \
  --ro-bind /sys/dev/char /sys/dev/char \
  --ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00 \
  $(for i in $(ls /dev/video* 2> /dev/null); do echo -n "--dev-bind-try $i $i "; done) \
  --unshare-all \
  --share-net \
  --die-with-parent \
  --chdir "$(pwd)" \
  --file 12 /etc/resolv.conf \
  --file 13 /etc/passwd \
  --file 14 /etc/group \
  /usr/local/bin/run.sh "${@}") \
  12< <(echo -e "options timeout:1\noptions rotate\nnameserver 1.1.1.1\nnameserver 9.9.9.9\nnameserver 149.112.112.112") \
  13< <(getent passwd $UID 65534) \
  14< <(getent group $(id -g) audio video 65534)
```

## Desktop integration

1. Add the following desktop (adjust `/home/username` dir!) file as `~/.local/share/applications/citrixwrapped.desktop` and link to auto open `.ica` files

```
[Desktop Entry]
Name=Citrix Wrapped Engine
Comment=Citrix Bubblewrapped
Terminal=false
Type=Application
StartupWMClass=Wfica
NoDisplay=true
Categories=Network;Office;
Icon=/home/username/.var/bwrap/citrixroot/opt/Citrix/ICAClient/icons/receiver.png
Exec=/home/username/bin/wfica.sh %f
MimeType=application/x-ica;application/vnd.citrix.receiver.configure;
```

# Update

1. Change version in Containerfile
2. `just build`
3. `just installforbwrap`
