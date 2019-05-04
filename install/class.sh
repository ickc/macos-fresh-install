#!/usr/bin/env bash

# install class on all *-(defaults|intel) conda environments
# set INSTALLDIR to customize where the git repo is located
# can be invoked repeatedly to update
# before running this script, an environment with Cython is needed
# to be loaded first

set -e

url="git@github.com:lesgourg/class_public.git"

# set install directory
if [[ -n $NERSC_HOST ]]; then
    defaultDir=/global/common/software/polar/git
	module swap gcc/8.2.0
else
    defaultDir="$HOME/git/fork"
fi
INSTALLDIR="${INSTALLDIR:-$defaultDir}"
NPROC="${NPROC:-$(nproc)}"
mkdir -p "$INSTALLDIR"

# obtain class
cd "$INSTALLDIR"
git clone "$url" class || (cd class && git reset --hard && git clean -d -f && git pull)

# compile
cd class
make clean

if [[ $(uname) == Darwin ]]; then
    make -j$NPROC OPTFLAG='-Ofast -ffast-math -march=native' CC=gcc-8
else
    make -j$NPROC OPTFLAG='-Ofast -ffast-math -march=native'
fi

# install in all conda environments that ends in -defaults or -intel
cd python
for i in $(grep -E -- '-(defaults|intel)' ~/.conda/environments.txt); do
    . activate $i
    pip install .
done
