#!/bin/bash

set -ex

CENTOS_RELEASE=${CENTOS_RELEASE:-7.6.1810}
# Upstream repository name. Usually os or updates.
CENTOS_REPO=${CENTOS_REPO:-os}
# SRPM filename.
CLOUD_INIT_SRPM=${CLOUD_INIT_SRPM:-cloud-init-18.2-1.el7.centos.src.rpm}
# Distribution patch number in the version.
CLOUD_INIT_DIST=${CLOUD_INIT_DIST:-100}
CLOUD_INIT_UPDATE=${CLOUD_INIT_UPDATE:-}
# The last patch in the spec file before Patch9999.
CLOUD_INIT_PATCHES=${CLOUD_INIT_PATCHES:-100}

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
git format-patch -1 c842e3d4914fa1289d463dc6f97cd786d7144e43 --stdout > $TOPDIR/SOURCES/00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch

# Modify specfile.
sed -i -e "s/^Release:.*$/Release:        ${CLOUD_INIT_DIST}%{?dist}${CLOUD_INIT_UPDATE}/" $TOPDIR/SPECS/cloud-init.spec
sed -i -e "/Patch9999:/i\
Patch00$((CLOUD_INIT_PATCHES + 1)): 00$((CLOUD_INIT_PATCHES + 1))-ib-interface-configdrive.patch" $TOPDIR/SPECS/cloud-init.spec

# Build
rpmbuild -ba $TOPDIR/SPECS/cloud-init.spec
echo Packages in $TOPDIR/RPMS and $TOPDIR/SRPMS
