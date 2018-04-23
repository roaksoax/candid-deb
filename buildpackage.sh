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
VERSION=$(sed -n -e '/^candid/ {s/^candid (\([0-9\.]*[~a-z0-9]*\).*$/\1/p; q}' debian/changelog)

if [ -z "$RELEASE" ]; then

# Get candid using git clone.
mkdir -p src/github.com/CanonicalLtd
cd src/github.com/CanonicalLtd
if [ -d candid ] ; then
    cd candid
    git pull
else
    git clone git@github.com:CanonicalLtd/candid.git candid
    cd candid
fi

# Get the short hash of the most recent commit for versioning.
SHORTHASH=$(git log -1 --pretty=format:%h)

# Update the debian/changelog file.
VERSION=${VERSION}+$(date -u +%Y%m%d%H%M)-${SHORTHASH}
dch -v ${VERSION} 'autobuild: new commit' -D bionic --check-dirname-level=0

fi

# Get all the dependent go source.
make -C $GOPATH/src/github.com/CanonicalLtd/candid deps

go test github.com/CanonicalLtd/candid/...

cd $GOPATH

GIT_COMMIT=`git --git-dir ${GOPATH}/src/github.com/CanonicalLtd/candid/.git rev-parse --verify HEAD`
PKG=github.com/CanonicalLtd/candid
VERSION_PKG=${PKG}/version
gofmt -r "unknownVersion -> Version{GitCommit: \"${GIT_COMMIT}\", Version: \"${VERSION}\",}" ${GOPATH}/src/${VERSION_PKG}/init.go.tmpl > ${GOPATH}/src/${VERSION_PKG}/init.go

# Build the source package.
dpkg-buildpackage -rfakeroot -F -us -uc
dpkg-buildpackage -rfakeroot -S -us -uc

CHANGESFILE=$(dpkg-parsechangelog | sed -rne 's,^Source: (.*),\1,p' )_$(dpkg-parsechangelog | sed -rne 's,^Version: (.*),\1,p')_source.changes

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
