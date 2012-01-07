#!/bin/sh

#TODO: should this also force init level to 5?

case "${1}" in
  RHEL_3)
    rm -f /etc/X11/XF86Config
    ;;
  RHEL_4)
    rm -f /etc/X11/xorg.conf
    ;;
  RHEL_5)
    rm -f /etc/X11/xorg.conf
    ;;
  RHEL_6)
    rm -f /etc/X11/xorg.conf
    ;;
  Fedora_2)
    rm -f /etc/X11/xorg.conf
    ;;
  Fedora_13)
    rm -f /etc/X11/xorg.conf
    ;;
  SUSE_9)
    rm -f /etc/X11/XF86Config
    ;;
esac
