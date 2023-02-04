#/usr/bin/env bash
set -euo pipefail
IMAGE="localhost/citrix:latest"
RUNPATH=${HOME}/run/citrixroot

if [[ ! -d $RUNPATH ]]; then
  mkdir -p $RUNPATH && podman export $(podman create $IMAGE) | tar -C $RUNPATH -xf -
fi

(exec /nix/store/c6s48595cal4y4l7gr8m029949x4a3nn-bubblewrap-0.7.0/bin/bwrap \
  --bind $RUNPATH / \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /etc/icalicense \
  --tmpfs $HOME \
  --dir /var \
  --chdir / \
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
  --setenv GTK_THEME A.dwaita:dark \
  --bind $HOME/Downloads $HOME/Downloads \
  --bind $HOME/.ICAClient $HOME/.ICAClient \
  --ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0 \
  --setenv DISPLAY "$DISPLAY" \
  --setenv HOME "$HOME" \
  --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/$UID/bus" \
  --ro-bind /run/user/$UID/bus /run/user/$UID/bus \
  --ro-bind /run/user/$UID/at-spi /run/user/$UID/at-spi \
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
  12< <(echo -e "nameserver 9.9.9.9\nnameserver 1.1.1.1\nnameserver 8.8.8.8")
