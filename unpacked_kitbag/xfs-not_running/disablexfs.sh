#!/bin/sh
#TODO: Should this also force initlevel to 5?

case "${1}" in
  RHEL_*)
    chkconfig xfs off
    ;;
  Fedora_*)
    chkconfig xfs off
    ;;
  SUSE_9)
    chkconfig -f xfs off
    ;;
esac
