Working around issues and wrapping Citrix Workplace App for Linux.


# Problem

- HdxEngine does not work if wayland .so are available (Teams optimization) → (Coredump when stopping screensharing)
- Wrap Citrix into it's own namespace (limit access to folders and devices)

# Dependencies

- Bubblewrap / brwap (https://github.com/containers/bubblewrap)
- podman or buildah (building the image)
- Chromium browser (if weblogin is needed)

# Limitations

- No hotplug of video devices (webcam)

# Solution

- Installation of Citrix Workspace App into a container
- Export the Container into a root filesystem
- Use bwrap to simulate a new root filesystem

Most of the time I use the weblogin and start `wfica` just to present the desktop. It is also possible to use `selfservice` login.

# My use case

It works for my use case. Using weblogin and starting the virtual desktop, using MS Teams with optimization, screensharing and webcam.

I mainly use it on NixOS.

I haven't tested smartcard login or USB redirection.

# Installation

1. Install podman (or buildah) to create the container (./build.sh)
2. Create `wfica.sh`. After that it is possible to run `./wfica.sh`, which will start `selfservice`, if an argument is added it starts `wfica` with that argument (see: `run.sh` in the container).

```
#/usr/bin/env bash
set -euo pipefail
IMAGE="localhost/citrix:latest"
RUNPATH=${HOME}/run/citrixroot

if [[ ! -d $RUNPATH ]]; then
  mkdir -p $RUNPATH && podman export $(podman create $IMAGE) | tar -C $RUNPATH -xf -
fi

(exec bwrap \
  --bind $RUNPATH / \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /var/log \
  --bind $HOME/.ICAClient/clientlicense /etc/icalicense/clientlicense \
  --tmpfs $HOME \
  --dir /var \
  --unshare-all \
  --share-net \
  --die-with-parent \
  --dir /run/user/$(id -u) \
  --clearenv \
  --setenv PS1 "citrix$ " \
  --setenv PATH "/bin:/usr/bin:/usr/local/bin" \
  --ro-bind $XAUTHORITY $HOME/.Xauthority \
  --setenv XDG_DATA_DIRS "/opt/kde/share:/usr/local/share:/usr/share" \
  --dir "$XDG_RUNTIME_DIR" \
  --ro-bind "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
  --ro-bind "$XDG_RUNTIME_DIR/pulse" "$XDG_RUNTIME_DIR/pulse" \
  --ro-bind "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus" \
  --setenv XDG_RUNTIME_DIR $XDG_RUNTIME_DIR \
  --setenv GTK_THEME Adwaita:dark \
  --bind $HOME/Downloads $HOME/Downloads \
  --bind $HOME/.ICAClient $HOME/.ICAClient \
  --ro-bind $HOME/.ICAClient/hdx_rtc_engine.json /var/.config/citrix/hdx_rtc_engine/config.json \
  --ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0 \
  --setenv DISPLAY "$DISPLAY" \
  --setenv TZ "Europe/Zurich" \
  --setenv HOME "$HOME" \
  --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$UID/bus" \
  --ro-bind /run/user/$UID/bus /run/user/$UID/bus \
  --ro-bind /run/user/$UID/at-spi /run/user/$UID/at-spi \
  --ro-bind-try /sys/class/power_supply /sys/class/power_supply \
  --ro-bind /sys/dev/char /sys/dev/char \
  --ro-bind /sys/devices /sys/devices \
  --ro-bind /run/dbus /run/dbus \
  --setenv LD_PRELOAD "libdl.so.2:/usr/local/lib/XlibNoSHM.so" \
  --dev-bind /dev/dri /dev/dri \
  $(for i in $(ls /dev/video* 2> /dev/null); do echo -n "--dev-bind-try $i $i "; done) \
  --unshare-all \
  --share-net \
  --chdir "$(pwd)" \
  --file 12 /etc/resolv.conf \
  /usr/local/bin/run.sh "$@") \
  12< <(echo -e "nameserver 149.112.112.112\nnameserver 1.0.0.3\nnameserver 1.1.1.3")
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
Icon=/home/username/run/citrixroot/opt/Citrix/ICAClient/icons/receiver.png
Exec=/home/username/bin/wfica.sh %f
MimeType=application/x-ica;application/vnd.citrix.receiver.configure;
```

# Update

1. `rm -rf ~/run/citrixroot`
2. Rebuild container
