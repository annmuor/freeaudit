#!/usr/bin/perl
# (C) kreon 2017
use strict;
use warnings;
use JSON;
use Sys::Hostname;

# config
our %grabs = (
  'centos|oraclelinux|redhat|fedora' => q(rpm -aq),
  'debian|ubuntu' => q(dpkg-query -W -f='${Package} ${Version} ${Architecture}\n'),
  'arch|manjaro' => q(pacman -Q),
  'osx' => q(pkgutil --pkgs)
);

our %unames = (
  'linux' => q(lsb_release -a),
  'darwin' => q(echo "Distributor ID: OSX")
);

# global vars
our $hostname = hostname;
our ($vercmd, $grabcmd, $operatingsystem, $version);

# detect OS by a perl way
my $uname = $^O;

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
