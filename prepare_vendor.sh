#!/bin/bash
# Taken from Fedora, modified to work with OM tooling and fix various issues.
# Original version:
# https://src.fedoraproject.org/rpms/python-sphinx-book-theme/raw/rawhide/f/prepare_vendor.sh

sudo dnf install rpmdevtools yarn

PKG_URL=$(rpmdev-spectool *.spec --source 0 | sed -e 's/Source0:[ ]*//g')
PKG_TARBALL=$(realpath .)/$(basename $PKG_URL)
PKG_NAME=$(rpmspec -q --queryformat="%{NAME}" *.spec --srpm | sed 's/^python-//' |sed -e 's,-,_,g')
PKG_VERSION=$(rpmspec -q --queryformat="%{VERSION}" *.spec --srpm)
PKG_SRCDIR="${PKG_NAME}-${PKG_VERSION}"
PKG_DIR="$PWD"
PKG_TMPDIR=$(mktemp --tmpdir -d ${PKG_NAME}-XXXXXXXX)
PKG_PATH="$PKG_TMPDIR/$PKG_SRCDIR/"

echo "URL:     $PKG_URL"
echo "TARBALL: $PKG_TARBALL"
echo "NAME:    $PKG_NAME"
echo "VERSION: $PKG_VERSION"
echo "PATH:    $PKG_PATH"

cleanup_tmpdir() {
    popd 2>/dev/null
    rm -rf $PKG_TMPDIR
    rm -rf /tmp/yarn--*
}
trap cleanup_tmpdir SIGINT

cleanup_and_exit() {
    cleanup_tmpdir
    if test "$1" = 0 -o -z "$1" ; then
        exit 0
    else
        exit $1
    fi
}

if [ ! -w "$PKG_TARBALL" ]; then
    wget "$PKG_URL"
fi


mkdir -p $PKG_TMPDIR
pushd "$PKG_TMPDIR"
tar xf $PKG_TARBALL
pwd
ls
popd

cd $PKG_PATH

export YARN_CACHE_FOLDER="$PWD/.package-cache"
echo ">>>>>> Install npm modules"
yarn install --frozen-lockfile
if [ $? -ne 0 ]; then
    echo "ERROR: yarn install failed"
    cleanup_and_exit 1
fi

echo ">>>>>> Package vendor files"
rm -f $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor.tar.xz
XZ_OPT="-9e -T$(nproc)" tar cJf $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor.tar.xz .package-cache
if [ $? -ne 0 ]; then
    cleanup_and_exit 1
fi

yarn add license-checker
yarn license-checker --summary | sed "s#$PKG_PATH#/tmp/#g" > $PKG_DIR/${PKG_NAME}-${PKG_VERSION}-vendor-licenses.txt

cd -

rm -rf .package-cache node_modules
cleanup_and_exit 0
