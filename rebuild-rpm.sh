#!/bin/bash

set -e

CENTOS_RELEASE=${CENTOS_RELEASE:-7.5.1804}
# Upstream repository name. Usually os or updates.
CENTOS_REPO=${CENTOS_REPO:-os}
# SRPM filename.
CLOUD_INIT_SRPM=${CLOUD_INIT_SRPM:-cloud-init-0.7.9-24.el7.centos.src.rpm}
# Distribution patch number in the version.
CLOUD_INIT_DIST=${CLOUD_INIT_DIST:-27}
CLOUD_INIT_UPDATE=${CLOUD_INIT_UPDATE:-}
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
git format-patch -1 0fec13275831c857ff4c1c0bb0c14f8fef9abb28 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch
git format-patch -1 872de67a9db5cf75c3f59734a6987aef80496a27 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 2))-convert-net-json-debug.patch
git format-patch -1 d9cbb0c18431ccb6173bed42f352e79febdb74bd --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 3))-fix-ipv6-default-gateway.patch
git format-patch -1 4ce60eabf424151a7cec5feda9859739b90db4c7 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 4))-infiniband-type.patch

# Modify specfile.
sed -i -e "s/^Release:.*$/Release:        ${CLOUD_INIT_DIST}%{?dist}${CLOUD_INIT_UPDATE}/" $TOPDIR/SPECS/cloud-init.spec
sed -i -e "/Patch9999:/i\
Patch00$((CLOUD_INIT_PATCHES + 1)): 00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch\n\
Patch00$((CLOUD_INIT_PATCHES + 2)): 00$((CLOUD_INIT_PATCHES + 2))-convert-net-json-debug.patch\n\
Patch00$((CLOUD_INIT_PATCHES + 3)): 00$((CLOUD_INIT_PATCHES + 3))-fix-ipv6-default-gateway.patch\n\
Patch00$((CLOUD_INIT_PATCHES + 4)): 00$((CLOUD_INIT_PATCHES + 4))-infiniband-type.patch" $TOPDIR/SPECS/cloud-init.spec

# Build
rpmbuild -ba $TOPDIR/SPECS/cloud-init.spec
echo Packages in $TOPDIR/RPMS and $TOPDIR/SRPMS
