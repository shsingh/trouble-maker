#!/bin/sh

RELEASE=${1}

mkdir -p usr/local/trouble-maker/bin
mkdir -p usr/local/trouble-maker/kitbag
cp tools/*.pl usr/local/trouble-maker/bin
cp engine/*.pl usr/local/trouble-maker/bin
chmod 700 usr/local/trouble-maker/bin/*
usr/local/trouble-maker/bin/pack_kitbag.pl unpacked_kitbag usr/local/trouble-maker/kitbag
tar cvfz trouble-maker-${RELEASE}.tgz usr/local/trouble-maker
rm -rf usr/local/trouble-maker

