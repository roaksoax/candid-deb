#!/usr/bin/perl
#
# get_changes_filename.pl
#
# Lifted from dpkg-buildpackage
#
# Used so I know what changes file was just written in ../ after running
# dpkg-buildpackage -rfakeroot -d -us -uc -S

use strict;
use warnings;

use Carp;
use Cwd;
use File::Basename;

use Dpkg ();
use Dpkg::Gettext;
use Dpkg::BuildOptions;
use Dpkg::Version;
use Dpkg::Changelog::Parse;

my $cwd = cwd();
my $dir = basename($cwd);

my $changelog = changelog_parse();

my $pkg = mustsetvar($changelog->{source}, _g('source package'));
my $version = mustsetvar($changelog->{version}, _g('source version'));
my $v = Dpkg::Version->new($version);
my ($ok, $error) = version_check($v);
error($error) unless $ok;

my $sversion = $v->as_string(omit_epoch => 1);
my $uversion = $v->version();

my $distribution = mustsetvar($changelog->{distribution}, _g('source distribution'));

my $arch;
$arch = 'source';

my $pva = "${pkg}_${sversion}_$arch";
print "$pva.changes\n";

sub mustsetvar {
    my ($var, $text) = @_;

    error(_g('unable to determine %s'), $text)
	unless defined($var);

    return $var;
}
