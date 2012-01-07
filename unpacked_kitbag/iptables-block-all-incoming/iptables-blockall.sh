#!/bin/sh

case "${1}" in
  RHEL_*)
    service iptables start
    iptables -I INPUT -p tcp -j DROP
    service iptables save
    ;;
  Fedora_*)
    service iptables start
    iptables -I INPUT -p tcp -j DROP
    service iptables save
    ;;
  SUSE_9)
    SuSEfirewall2 start
    iptables -I INPUT -p tcp -j DROP
    head -n -4 /sbin/SuSEfirewall2 > /sbin/SuSEfirewall2.new
    echo "iptables -I INPUT -p tcp -j DROP" >> /sbin/SuSEfirewall2.new
    tail -4 /sbin/SuSEfirewall2 >> /sbin/SuSEfirewall2.new
    rm -f /sbin/SuSEfirewall2
    mv /sbin/SuSEfirewall2.new /sbin/SuSEfirewall2
    chmod 755 /sbin/SuSEfirewall2
    ;;
esac

