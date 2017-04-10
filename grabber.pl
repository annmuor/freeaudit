#!/usr/bin/perl
# (C) kreon 2016
use strict;
use warnings;
use JSON;
# config
our %grabs = (
  'centos|oraclelinux|redhat|fedora' => q(rpm -aq),
  'debian|ubuntu' => q(dpkg-query -W -f='${Package} ${Version} ${Architecture}\n'),
  'osx' => q(pkgutil --pkgs)
);

our %unames = (
  'linux' => q(lsb_release -a),
  'darwin' => q(echo "Distributor ID: OSX")
);
# global vars
our $hostname = `hostname -f`;
our ($vercmd, $grabcmd, $operatingsystem, $version);
# do uname
my $uname = `uname`;
chomp $uname;

foreach (keys %unames) {
  $vercmd = $unames{$_} if $uname =~ /$_/i;
}

die "Version CMD not found" unless $vercmd;

# do version check
foreach (`$vercmd`) {
    chomp;
    /^Distributor ID:\s*(\S[\S\s]+)$/ and $operatingsystem  = $1;
    /^Release:\s*(\S[\S\s]+)$/        and $version = $1;
}

die "Opetating System not found" unless $operatingsystem;

foreach (keys %grabs) {
  $grabcmd = $grabs{$_} if $operatingsystem =~ /$_/i;
}

# grab pkgs
die "Opetating System not found" unless $grabcmd;
my @pkgs;
foreach (`$grabcmd`) {
    chomp;
    push @pkgs, $_;
}
chomp $hostname;

my $result = {
    hostname => $hostname,
    os       => $version ? qq($operatingsystem $version) : $operatingsystem,
    pkgs     => [ sort @pkgs ]
};
#
print JSON->new->encode($result);

# done
1;
