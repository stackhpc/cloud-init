#!/bin/bash

set -e

SRPM=http://vault.centos.org/7.4.1708/updates/Source/SPackages/cloud-init-0.7.9-9.el7.centos.6.src.rpm
TOPDIR=~/rpmbuild

# Download & install SRPM.
tempdir=$(mktemp -d)
pushd $tempdir
wget $SRPM
rpm -ivh $(basename $SRPM)
sudo yum-builddep cloud-init
rpmbuild -bp $TOPDIR/SPECS/cloud-init.spec
popd
rm -rf $tempdir

# Generate patches
git format-patch -1 891833fecd810cd7cc7899575f1c3cc620399577 --stdout > $TOPDIR/SOURCES/0034-ib-interface-configdrive.patch
git format-patch -1 02e439e76bad7cf2c6ee95693e791ca7d1a31a28 --stdout > $TOPDIR/SOURCES/0035-convert-net-json-debug.patch

# Modify specfile.
sed -i -e "s/^Release:.*$/Release:        9%{?dist}.7/" $TOPDIR/SPECS/cloud-init.spec
sed -i -e "/Patch9999:/i\
Patch0034: 0034-ib-interface-configdrive.patch\n\
Patch0035: 0035-convert-net-json-debug.patch" $TOPDIR/SPECS/cloud-init.spec

# Build
rpmbuild -ba $TOPDIR/SPECS/cloud-init.spec
echo Packages in $TOPDIR/RPMS and $TOPDIR/SRPMS
