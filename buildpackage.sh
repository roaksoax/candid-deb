#!/bin/sh

set -e

script_name=${0##*/}

usage () {
cat <<EOT
Description: Clone and/or update source, update debian/changelog and
             build a deb.

Usage: $script_name [options]
Options:

-r     : A release was prepped, do not update source or debian/changelog.
-s     : Do not sign. Useful for when a key is not available.
-v     : Verbose output.
EOT
}

while getopts "rshv" opt
do
    case "$opt" in
        r)
            RELEASE=true
        ;;
        s)
            NOSIGN=true
        ;;
        v)
            set -x
        ;;
        h)
            usage
            exit 0
        ;;
esac
done

: ${TARGETPPA:=ppa:yellow/theblues-unstable}

export GOPATH=$(pwd)
VERSION=$(sed -n -e '/^blues-identity/ {s/^blues-identity (\([0-9\.]*\).*$/\1/p; q}' debian/changelog)

if [ -z "$RELEASE" ]; then

# Get blues-identity using git clone.
mkdir -p src/github.com/CanonicalLtd
cd src/github.com/CanonicalLtd
if [ -d blues-identity ] ; then
    cd blues-identity
    git pull
else
    git clone git@github.com:CanonicalLtd/blues-identity.git blues-identity
    cd blues-identity
fi

# Get the short hash of the most recent commit for versioning.
SHORTHASH=$(git log -1 --pretty=format:%h)

# Get all the dependent go source.
make deps

go test github.com/CanonicalLtd/blues-identity/...

cd $GOPATH

# Update the debian/changelog file.
VERSION=${VERSION}+$(date -u +%Y%m%d%H%M)-${SHORTHASH}
dch -v ${VERSION} 'autobuild: new commit' -D trusty

fi

# TODO(mhilton) uncomment this when blues-identity has a version package similar to charmstore.
#GIT_COMMIT=`git --git-dir ${GOPATH}/src/github.com/CanonicalLtd/blues-identity/.git rev-parse --verify HEAD`
#PKG=github.com/CanonicalLtd/blues-identity
#VERSION_PKG=${PKG}/version
#mkdir -p src_version/src/${VERSION_PKG}
#cp ${GOPATH}/src/${VERSION_PKG}/*.go ${GOPATH}/src_version/src/${VERSION_PKG}
#cp ${GOPATH}/src/${PKG}/*.go src_version/src/${PKG}
#gofmt -w -r "unknownVersion -> Version{GitCommit: \"${GIT_COMMIT}\", Version: \"${VERSION}\",}" ${GOPATH}/src_version/src/${VERSION_PKG}/version.go

# Build the source package.
dpkg-buildpackage -rfakeroot -d -S -us -uc

CHANGESFILE=$(./get_changes_filename.pl)

if [ -z "$NOSIGN" ]; then
# dpkg-buildpackage doesn't prompt for passwork when signing.
# call debsign
debsign ../${CHANGESFILE}
fi

# Upload the build package to a PPA
set +x
echo
echo "Uploading the PPA is a manual step. To upload, run the following command:"
echo "  dput ${TARGETPPA} ../${CHANGESFILE}"
echo
