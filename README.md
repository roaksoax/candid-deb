blues-identity debian package source
====================================

This repository contains only the debian packaging part of blues-identity.

## Installing Packages

 1. Login to launchpad and go to https://launchpad.net/~/+archivesubscriptions
 1. Click the `View` link for `theblues` or `theblues-unstable`
 1. Follow the instructions to add the PPA
 1. sudo apt-get update ; sudo apt-get install blues-identity

## Build Dependencies

Package building requirements are the same as blues-identity.

Build dependencies are specified in debian/control, but if they change and
the source packages are not yet in a PPA, then `apt-get build-dep` will not
be able to install the build dependencies for you.

    $ sudo apt-get install build-essential bzr debhelper devscripts git golang-go lsb-release mercurial

Running tests requires mongodb-server package to be installed.

    $ sudo apt-get update
    $ sudo apt-get install mongodb-server

## Development Packages

To build a development debian package, suitable for a development or daily
PPA, checkout this repository and run buildpackage.sh.

The buildpackage.sh script calls `dch` and adds a new version entry to
`debian/changelog` with your name in it. You should have `DEBEMAIL` and
`DEBFULLNAME` set. `dch` tries to figure out who is revising the package and
uses these environment variables to update `debian/changelog`. See `dch(1)` for
details.

### Example environment variables:

    DEBEMAIL=jay.wren@canonical.com
    DEBFULLNAME='Jay R. Wren'

*dch will set the package author in changelog to 'Jay R. Wren
<jay.wren@canonical.com>'*

### Uploading

The end of the `buildpackage.sh` command prints the `dput` command to use to
upload to the PPA. This is manual to prevent excessive or mistake uploads to
the PPA. If you really want to publish to PPA, run this command.

Once you have uploaded to the PPA you should add and commit the changes to
`debian/changelog` and push them to the git repository.

### Notes

This workflow is not
https://wiki.debian.org/Python/GitPackaging. The GitPackaging workflow is still
release tarball centric with an upstream branch being equivalent to a tarball,
the pristine-tar branch being delta and a master branch being upstream with
debian directory. This workflow did not seem to match well with what we needed.

The debian packages are in 3.0 (native) format, not 3.0 (quilt) format as a
result of our needs.

Golang is not compatible with bzr-builder.

    14:30    sinzui| jrwren, no, golang is 100% incompatible with bzr-builder
    and Lp's security policies

This rules out using build recipes on Launchpad.

The process for building a package will be roughly based on juju-core checklist.
https://docs.google.com/a/canonical.com/document/d/1hBK3Q-DG8vAnZ3E_RVfr1KLks3MC_5tT5O6U0LbscJo/edit#heading=h.m6cs1kc4eaqn

## Release Packages

The buildpackage.sh script is for building a daily or snapshot development
package. To build a release package, follow steps in `RELEASE_PROCESS.md`.

## Verifying Packaged Binaries

In the course of executing a binary from a debian package, it may be necessary
to verify that the binaries are built the way that you think that they are. Two
methods are possible. One is to download the source debian package from the PPA
and confirm that the source which you expected is used. Another is to inspect
the binaries yourself.

### Verifying Using Source Packages

 1. Include the deb-src line in the PPA configuration.
   - See `Installing Packages` above.
 1. `apt-get source blues-identity`
 1. Inspect the source which was just downloaded.

### Verifying Using Binaries

 1. Find a difference which you expect to be in the binary using git diff.
   - e.g. `git diff 0.1.0..0.1.1`

     https://github.com/CanonicalLtd/blues-identity/compare/0.1.0...0.1.1

   - Look for an easy difference such as a new package level symbol. e.g.
     entityExists endpoint added
 1. Run strings on the binary in question and grep for the symbol.

    ```
    $ strings /usr/bin/idserver | grep entityExists
    ...
    github.com/CanonicalLtd/blues-identity/internal/v1.(*Handler).entityExists
    ...
    ```
    The symbol is listed, so this binary must be built from the right tag  (or
    potentially newer) because the symbol does not exist in that older tag.

    Another possibility is that the symbol is not there, but this does not
    necessarily mean that an older version of library was used. Study the very
    short diff between 0.1.0 and 0.2.0 in github.com/CanonicalLtd/blues-identity.
