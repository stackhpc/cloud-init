# Copyright (C) 2009 Canonical Ltd.
# Copyright (C) 2012 Yahoo! Inc.
#
# Author: Soren Hansen <soren@canonical.com>
# Author: Joshua Harlow <harlowja@yahoo-inc.com>
#
# This file is part of cloud-init.  See LICENSE file for license information.

# Distutils magic for ec2-init

from glob import glob

import os
import sys

import setuptools
from setuptools.command.install import install

from distutils.errors import DistutilsArgError

import subprocess


def is_f(p):
    return os.path.isfile(p)


def tiny_p(cmd, capture=True):
    # Darn python 2.6 doesn't have check_output (argggg)
    stdout = subprocess.PIPE
    stderr = subprocess.PIPE
    if not capture:
        stdout = None
        stderr = None
    sp = subprocess.Popen(cmd, stdout=stdout,
                          stderr=stderr, stdin=None,
                          universal_newlines=True)
    (out, err) = sp.communicate()
    ret = sp.returncode
    if ret not in [0]:
        raise RuntimeError("Failed running %s [rc=%s] (%s, %s)" %
                           (cmd, ret, out, err))
    return (out, err)


def pkg_config_read(library, var):
    fallbacks = {
        'systemd': {
            'systemdsystemunitdir': '/lib/systemd/system',
            'systemdsystemgeneratordir': '/lib/systemd/system-generators',
        }
    }
    cmd = ['pkg-config', '--variable=%s' % var, library]
    try:
        (path, err) = tiny_p(cmd)
    except Exception:
        return fallbacks[library][var]
    return str(path).strip()


INITSYS_FILES = {
    'sysvinit': [f for f in glob('sysvinit/redhat/*') if is_f(f)],
    'sysvinit_freebsd': [f for f in glob('sysvinit/freebsd/*') if is_f(f)],
    'sysvinit_deb': [f for f in glob('sysvinit/debian/*') if is_f(f)],
    'sysvinit_openrc': [f for f in glob('sysvinit/gentoo/*') if is_f(f)],
    'upstart': [f for f in glob('upstart/*') if is_f(f)],
}
INITSYS_ROOTS = {
    'sysvinit': '/etc/rc.d/init.d',
    'sysvinit_freebsd': '/usr/local/etc/rc.d',
    'sysvinit_deb': '/etc/init.d',
    'sysvinit_openrc': '/etc/init.d',
    'upstart': '/etc/init/',
}
INITSYS_TYPES = sorted([f.partition(".")[0] for f in INITSYS_ROOTS.keys()])

# Install everything in the right location and take care of Linux (default) and
# FreeBSD systems.
USR = "/usr"
ETC = "/etc"
USR_LIB_EXEC = "/usr/lib"
LIB = "/lib"
if os.uname()[0] == 'FreeBSD':
    USR = "/usr/local"
    USR_LIB_EXEC = "/usr/local/lib"
    ETC = "/usr/local/etc"
elif os.path.isfile('/etc/redhat-release'):
    USR_LIB_EXEC = "/usr/libexec"


# Avoid having datafiles installed in a virtualenv...
def in_virtualenv():
    try:
        if sys.real_prefix == sys.prefix:
            return False
        else:
            return True
    except AttributeError:
        return False


def get_version():
    cmd = [sys.executable, 'tools/read-version']
    (ver, _e) = tiny_p(cmd)
    return str(ver).strip()


def read_requires():
    cmd = [sys.executable, 'tools/read-dependencies']
    (deps, _e) = tiny_p(cmd)
    return str(deps).splitlines()


if in_virtualenv():
    data_files = []
else:
    data_files = [
        (ETC + '/cloud', glob('config/*.cfg')),
        (ETC + '/cloud/cloud.cfg.d', glob('config/cloud.cfg.d/*')),
        (ETC + '/cloud/templates', glob('templates/*')),
        (ETC + '/NetworkManager/dispatcher.d/', ['tools/hook-network-manager']),
        (USR_LIB_EXEC + '/cloud-init', ['tools/uncloud-init',
                                        'tools/write-ssh-key-fingerprints']),
        (USR + '/share/doc/cloud-init', [f for f in glob('doc/*') if is_f(f)]),
        (USR + '/share/doc/cloud-init/examples',
            [f for f in glob('doc/examples/*') if is_f(f)]),
        (USR + '/share/doc/cloud-init/examples/seed',
            [f for f in glob('doc/examples/seed/*') if is_f(f)]),
        ('/usr/lib/udev/rules.d', [f for f in glob('udev/*.rules')]),
    ]


requirements = read_requires()
if sys.version_info < (3,):
    requirements.append('cheetah')

setuptools.setup(
    name='cloud-init',
    version=get_version(),
    description='EC2 initialisation magic',
    author='Scott Moser',
    author_email='scott.moser@canonical.com',
    url='http://launchpad.net/cloud-init/',
    packages=setuptools.find_packages(exclude=['tests']),
    scripts=['tools/cloud-init-per'],
    license='Dual-licensed under GPLv3 or Apache 2.0',
    data_files=data_files,
    entry_points={
        'console_scripts': [
            'cloud-init = cloudinit.cmd.main:main'
        ],
    }
)

# vi: ts=4 expandtab
