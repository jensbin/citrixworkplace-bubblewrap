FROM library/ubuntu:20.04

ARG username

ENV DEBIAN_FRONTEND noninteractive

COPY ./01_nodoc /etc/dpkg/dpkg.cfg.d/
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y apt-utils xdg-utils libwebkit2gtk-4.0-37 libgtk2.0-0 procps \
                       gnome-keyring libsecret-1-0 libxmu6 libxpm4 dbus-x11 \
                       xauth libcurl4 libcurl3-gnutls wget lsb-release wget curl sudo \
                       software-properties-common gnupg libidn11 libc++1 liboss4-salsa-asound2 \
                       libc++abi1 pulseaudio-utils locales materia-gtk-theme && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen && \
    apt-get clean && apt-get autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add -
RUN echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-12 main" >> /etc/apt/sources.list
RUN apt-get update && apt-get install -y libunwind-12 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY XlibNoSHM.c /
RUN apt-get update && \
    apt-get install -y gcc libc-dev libxext-dev && \
    mkdir -p /usr/local/lib && \
    gcc /XlibNoSHM.c -shared -nostdlib -o /usr/local/lib/XlibNoSHM.so && \
    rm /XlibNoSHM.c && \
    apt-get remove -y gcc libc-dev libxext-dev && \
    apt autoremove -y && \
    apt-get clean && apt-get autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -ms /bin/bash $username

RUN wget $(wget -O - https://www.citrix.com/downloads/workspace-app/linux/workspace-app-for-linux-latest.html | sed -ne '/icaclient_.*_amd64\.deb/ s/<a .* rel="\(.*\)" id="downloadcomponent">/https:\1/p' | sed -e 's/\r//g') -O /tmp/icaclient.deb
RUN apt-get update && dpkg -i /tmp/icaclient.deb && apt-get -y -f install && rm -f /tmp/icaclient.deb && apt-get clean && apt-get autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/icalicense
RUN ln -s /usr/share/ca-certificates/mozilla/* /opt/Citrix/ICAClient/keystore/cacerts/ && /opt/Citrix/ICAClient/util/ctx_rehash 
#RUN bash -c 'for i in /usr/share/ca-certificates/mozilla/*; do [[ $(date -d "$(openssl x509 -enddate -noout -in $i | cut -d '=' -f 2)" +%s) -ge $(date +%s) ]] && ln -s $i /opt/Citrix/ICAClient/keystore/cacerts/; done' && /opt/Citrix/ICAClient/util/ctx_rehash 

# create /config/.server to enable user customization using ~/.ICACLient/ overrides. Thanks Tomek
#RUN touch /opt/Citrix/ICAClient/config/.server

RUN sed -i \
        -e 's/Ceip=Enable/Ceip=Disable/' \
        -e 's/EnableLaunchDarkly=Enable/EnableLaunchDarkly=Disable/' \
        -e 's/DisableHeartBeat=False/DisableHeartBeat=True/' \
        /opt/Citrix/ICAClient/config/module.ini
#RUN sed -i '3i\\t<key>gRPCEnabled</key><value>false</value>' /opt/Citrix/ICAClient/config/AuthManConfig.xml
#RUN sed -i '3i\\t<GnomeKeyringDisabled>true</GnomeKeyringDisabled>' /opt/Citrix/ICAClient/config/AuthManConfig.xml
RUN ln -fs gst_play1.0 /opt/Citrix/ICAClient/util/gst_play ; ln -fs gst_read1.0 /opt/Citrix/ICAClient/util/gst_read
RUN rm /opt/Citrix/ICAClient/lib/UIDialogLibWebKit.so

RUN echo 'exit 0' > /usr/local/bin/lldpcli && chmod 755 /usr/local/bin/lldpcli
RUN echo 'exit 0' > /usr/local/bin/udevadm && chmod 755 /usr/local/bin/udevadm

RUN find /usr/share/doc -depth -type f ! -name copyright | xargs rm || true
RUN find /usr/share/doc -empty | xargs rmdir || true
RUN rm -rf /usr/share/man /usr/share/groff /usr/share/info /usr/share/lintian /usr/share/linda /var/cache/man /var/log/*
RUN find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' | xargs rm -r
ADD run.sh /usr/local/bin/run.sh
RUN chmod 755 /usr/local/bin/run.sh

#ENTRYPOINT [ "/usr/local/bin/run.sh" ]

