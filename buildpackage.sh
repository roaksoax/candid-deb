#!/bin/sh

set -ex

: ${TARGETPPA:=ppa:yellow/theblues-unstable}

GOPATH=$(pwd)
VERSION=$(sed -n -e '/^blues-identity/ {s/^blues-identity (\([0-9\.]*\).*$/\1/p; q}' debian/changelog)

if [ "$1" != "release" ]; then

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

GIT_COMMIT=`git --git-dir ${GOPATH}/src/github.com/CanonicalLtd/blues-identity/.git rev-parse --verify HEAD`
PKG=github.com/CanonicalLtd/blues-identity
VERSION_PKG=${PKG}/version
gofmt -r "unknownVersion -> Version{GitCommit: \"${GIT_COMMIT}\", Version: \"${VERSION}\",}" ${GOPATH}/src/${VERSION_PKG}/init.go.tmpl > ${GOPATH}/src/${VERSION_PKG}/init.go

# Build the source package.
dpkg-buildpackage -rfakeroot -d -S -us -uc

CHANGESFILE=$(./get_changes_filename.pl)

# dpkg-buildpackage doesn't prompt for passwork when signing.
# call debsign
debsign ../${CHANGESFILE}

# Upload the build package to a PPA
set +x
echo
echo "Uploading the PPA is a manual step. To upload, run the following command:"
echo "  dput ${TARGETPPA} ../${CHANGESFILE}"
echo
