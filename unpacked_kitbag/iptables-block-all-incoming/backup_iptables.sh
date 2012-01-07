#!/bin/sh

echo "____________________________________________________________"
echo "This was the state of iptables before the trouble module was run:"
echo "____________________________________________________________"
iptables -L -v -n

case "${1}" in
  RHEL_*)
    service iptables start
    ;;
  Fedora_*)
    service iptables start
    ;;
  SUSE_9)
    SuSEfirewall2 start
    ;;
esac

echo "____________________________________________________________"
echo "This was the state of iptables before the trouble module was run, after forcing the firewall to on"
echo "____________________________________________________________"
iptables -L -v -n
