#!/bin/sh
for i in /boot/init*;
    do
    mv $i $i.missing;
done
