#!/bin/bash

export GTK_THEME="Materia:light-compact"
#export GTK_THEME_VARIANT="light"
export GTK2_RC_FILES="/usr/share/themes/Materia-light-compact/gtk-2.0/gtkrc"

[[ -d ~/.ICAClient ]] || mkdir -p ~/.ICAClient
[[ -d ~/.ICAClient/.eula_accepted ]] || touch ~/.ICAClient/.eula_accepted
export ICAROOT=/opt/Citrix/ICAClient
#Start the Citrix logging service
$ICAROOT/util/ctxcwalogd

[[ -f /usr/local/lib/XlibNoSHM.so ]] && export LD_PRELOAD="libdl.so.2:/usr/local/lib/XlibNoSHM.so"

if [[ ! -f "$@" ]]; then
  $ICAROOT/selfservice
else
  $ICAROOT/wfica -icaroot $ICAROOT "$@"
  #exec /app/ICAClient/linuxx64/wfica -icaroot /app/ICAClient/linuxx64 "$@"
fi

#This services seems to (sometimes) get started when launching Workspace. It's stubborn and requires SIGKILL to stop.
if [[ ! -z $(ps -e | grep UtilDaemon) ]]; then
    pkill --signal 9 UtilDaemon
fi

#Kill the rest of the services that were started, so the Flatpak container itself stops running once you close Workspace.
for process in AuthManagerDaem ServiceRecord ctxcwalogd icasessionmgr; do
    pkill $process
done

exit
