#!/usr/bin/env bash

# Copyright (C) 2012 Rogério Carvalho Schneider <stockrt@gmail.com>
#
# This file is part of python-install.
#
# python-install is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# python-install is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with python-install.  If not, see <http://www.gnu.org/licenses/>.
#
#
# python-install.sh
#
# Created:  Mar 10, 2011
# Author:   Rogério Carvalho Schneider <stockrt@gmail.com>

#python_version="${PYTHON_VERSION:-2.5.6}"
#python_version="${PYTHON_VERSION:-2.6.8}"
python_version="${PYTHON_VERSION:-2.7.10}"
py_ver="${python_version:0:1}"
py_maj="${python_version:2:1}"
py_min="${python_version:4:2}"
python_src_version="${py_ver}.${py_maj}.${py_min}"
python_src_download_url="http://www.python.org/ftp/python/$python_src_version/Python-$python_src_version.tar.bz2"
python_src_prefix="/usr/python${py_ver}${py_maj}"
download_dir="/tmp/python-install"
wget="wget -q -c"

use_source="false"
if [[ "$1" == "-s" ]]
then
    use_source="true"
fi

basedir="$(dirname $0)"
cd "$basedir"
basedir="$PWD"

die () {
    echo
    echo "Error: An error occurred. Please see above."
    echo
    exit 1
}

os_install () {
    package="$1"
    echo "Installing with OS native package tool: $package"
    (type port >/dev/null 2>&1 && sudo port install $package) || \
    (type yum >/dev/null 2>&1 && sudo yum -y install $package) || \
    (type apt-get >/dev/null 2>&1 && sudo apt-get -y install $package)
    (type emerge >/dev/null 2>&1 && sudo emerge $package)
}

install_python () {
    echo
    echo "Installing Python ..."

    python_bin="$(which python${py_ver}.${py_maj} 2>/dev/null)"

    # not src
    if [[ "$python_bin" == "" && "$use_source" == "false" ]]
    then
        # emerge
        os_install "python"
        os_install "sqlite"

        # apt-get / yum
        os_install "python${py_ver}.${py_maj}"

        # apt-get
        os_install "libsqlite3-dev"

        # yum
        os_install "sqlite-devel"

        # ports
        os_install "python${py_ver}${py_maj}"
        os_install "py${py_ver}${py_maj}-sqlite3"

        python_bin="$(which python${py_ver}.${py_maj} 2>/dev/null)"
    fi

    # src
    if [[ "$python_bin" == "" || "$use_source" == "true" ]]
    then
        if [[ ! -f "$python_src_prefix/bin/python" ]]
        then
            echo
            echo "Downloading Python ..."
            mkdir -p $download_dir >/dev/null 2>&1
            cd $download_dir || die
            $wget $python_src_download_url || die

            echo
            echo "Extracting Python ..."
            tar xjmf Python-$python_src_version.tar.bz2 || die
            cd Python-$python_src_version || die

            echo
            echo "Configuring Python (output on $download_dir/python.log) ..."
            ./configure --prefix=$python_src_prefix > $download_dir/python.log 2>&1 || die

            echo
            echo "Building Python (output on $download_dir/python.log) ..."
            make >> $download_dir/python.log 2>&1 || die

            echo
            echo "Installing Python (output on $download_dir/python.log) ..."
            sudo make install >> $download_dir/python.log 2>&1 || die
        fi

        python_bin="$python_src_prefix/bin/python"
    fi
}

all_start_message () {
    echo "
Using:
    Python full version:    $python_version
    Python version:         $py_ver
    Python major:           $py_maj
    Python minor:           $py_min
    Downloads:              $download_dir

You may override some of this by setting env vars:
    export PYTHON_VERSION=\"$python_version\"
    $basedir/python-install.sh
or at once:
    PYTHON_VERSION=\"$python_version\" $basedir/python-install.sh
use -s to install from source:
    PYTHON_VERSION=\"$python_version\" $basedir/python-install.sh -s"
}

all_end_message () {
    echo "
Python ${py_ver}.${py_maj} installed at: $python_bin

Done.
"
}

##########
## MAIN ##
##########

all_start_message
install_python
all_end_message
