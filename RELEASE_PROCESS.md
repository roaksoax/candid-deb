## Find the last release in blues-identity

We tag release commits with lightweight tags. You can check the last release by
running `git tag | sort -V` and finding the largest version number.

export tagname=<current largest tag>
export newtag=<next semver>

## Generate changelog

We structure merge commit messages to be a short summary of the change. As such
you can get a quick log of all the major changes since the last release with
`git log`.

    git log $tagname...HEAD --author 'jujugui' --format='* [%h] %b'

Use the output from that to update the changelog with the major changes of the
release. You can verify that the changelog makes sense by also looking at the
diff since the last release.

    git diff $tagname...HEAD

In blues-identity-deb, use `dch` to add these to the `debian/changelog`. This
command will start an `EDITOR` and allow you to write bullets into the
`debian/changelog`.

    dch -v $newtag -D trusty

Once done do not forget to make a pull request for the debian/changelog
modifications on github.  After approved and merge, continue with the next steps.

## Create The Release

This debian package builds from the `blues-identity` and source. The repository
should be tagged with a version. These instructions assume you have already
pulled the source for the go package from previous use of `buildpackage.sh`.
Run these commands from the root of a`blues-identity-deb` branch.

    export GOPATH=$(pwd)
    cd src/github.com/CanonicalLtd/blues-identity
    git pull
    git tag -a $newtag -m "tag $newtag for release"
    git push origin $newtag
    cd $GOPATH

## run buildpackage.sh with the release argument

    ./buildpackage.sh -vr

This will update the version values in
github.com/CanonicalLtd/blues-browser/version/version.go to match the current
deb version and current git commit. Note: the blues-identity doesn't currently have
this package.

Read the end output of this command carefully. If the previous step did not
sign, then sign the dsc and changes file.

    debsign ../blues-identity_$newtag_source.changes

Signing may choose the wrong private key if you have multiple. Use the `-m`
option to pick an email address and sign.

## Build Binary Package

    dpkg-buildpackage -rfakeroot -d

## Check Binary Package

    dpkg-deb -c ../<package that was created>.deb
    sudo dpkg -i ../<package that was created>.deb

Check that executables run. 
```
cp /etc/blues-identity/config.yaml.sample /etc/blues-identity/config.yaml`
```
Start the service:
Before xenial: `sudo service blues-identity start`
Xenial and beyond: `sudo systemctl start blues-identity`

If, in the process of checking, you find an error, fix it upstream and update
the tag with `git -f $newtag`. Do not forget to `git push -f` to get
it to the remote.


## Upload to PPA

    dput ppa:yellow/theblues-unstable ../blues-identity_$newtag_source.changes

Once the packages are built, use launchpad to copy packages to the stable PPA.

https://launchpad.net/~yellow/+archive/ubuntu/theblues-unstable/+copy-packages

Commit your changes.
