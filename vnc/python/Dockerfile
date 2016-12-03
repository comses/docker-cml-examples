FROM vnc_base

MAINTAINER CoMSES "comses@asu.edu"

ADD .vnc /root/.vnc
ADD .config /root/.config
ADD scripts /root/scripts
RUN chmod +x /root/.vnc/xstartup /etc/X11/xinit/xinitrc /root/scripts/*.sh

ENTRYPOINT ["/root/scripts/vnc_startup.sh"]
CMD ["--tail-log"]
