#!/bin/bash

set -e

CENTOS_RELEASE=${CENTOS_RELEASE:-7.5.1804}
# Upstream repository name. Usually os or updates.
CENTOS_REPO=${CENTOS_REPO:-os}
# SRPM filename.
CLOUD_INIT_SRPM=${CLOUD_INIT_SRPM:-cloud-init-0.7.9-24.el7.centos.src.rpm}
# Distribution patch number in the version.
CLOUD_INIT_DIST=${CLOUD_INIT_DIST:-24}
# The last patch in the spec file before Patch9999.
CLOUD_INIT_PATCHES=${CLOUD_INIT_PATCHES:-39}

SRPM=http://vault.centos.org/${CENTOS_RELEASE}/${CENTOS_REPO}/Source/SPackages/${CLOUD_INIT_SRPM}
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
git format-patch -1 891833fecd810cd7cc7899575f1c3cc620399577 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch
git format-patch -1 02e439e76bad7cf2c6ee95693e791ca7d1a31a28 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 2))-convert-net-json-debug.patch

# Modify specfile.
sed -i -e "s/^Release:.*$/Release:        9%{?dist}.$((CLOUD_INIT_DIST + 1))/" $TOPDIR/SPECS/cloud-init.spec
sed -i -e "/Patch9999:/i\
Patch00$((CLOUD_INIT_PATCHES + 1)): 00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch\n\
Patch00$((CLOUD_INIT_PATCHES + 2)): 00$((CLOUD_INIT_PATCHES + 2))-convert-net-json-debug.patch" $TOPDIR/SPECS/cloud-init.spec

# Build
rpmbuild -ba $TOPDIR/SPECS/cloud-init.spec
echo Packages in $TOPDIR/RPMS and $TOPDIR/SRPMS
