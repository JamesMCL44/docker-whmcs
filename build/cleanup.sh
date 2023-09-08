#!/bin/bash
set -e

apt-get -y --purge autoremove
apt-get -y clean 
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
