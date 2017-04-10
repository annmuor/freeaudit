#!/usr/bin/perl
# (C) kreon 2017
use strict;
use warnings;
use lib 'perl5';
use HTTP::Tiny;
use DBI;
use JSON;
use constant DB                => 'dbi:Pg:dbname=pkgs';

our $dbh;
our @hosts;
# 0. connect to DB
$dbh = DBI->connect( DB, "", "", { RaiseError => 1, AutoCommit => 0 } );
# get top20 hosts
my $sth = $dbh->prepare("SELECT h.hostname,SUM(v.cvss_score) as sum FROM hosts h INNER JOIN pkg p ON(p.id=ANY(h.pkg_id)) INNER JOIN v2p vp ON(vp.pkg_id=p.id) INNER JOIN vulners v ON (v.id=vp.vuln_id) GROUP BY h.hostname ORDER BY sum DESC LIMIT 10");
$sth->execute();
while (my ($host, $sum) = $sth->fetchrow_array) {
  push @hosts, { hostname => $host, score => $sum, pkgs => [] };
}
foreach (@hosts) {
  $sth = $dbh->prepare("SELECT p.name,SUM(v.cvss_score) AS score FROM pkg p RIGHT JOIN hosts h ON (p.id=ANY(h.pkg_id)) INNER JOIN v2p ON (v2p.pkg_id=p.id) INNER JOIN vulners v ON (v.id=v2p.vuln_id) WHERE h.hostname=? GROUP BY p.name ORDER BY score DESC LIMIT 10");
  $sth->execute(($_->{hostname}));
  while(my ($pkg,$sum) = $sth->fetchrow_array) {
    push @{$_->{pkgs}}, { package => $pkg, score => $sum };
  }
}

print <<EOF
         TOP 10 SERVERS TO UPDATE
EOF
;
foreach (@hosts) {
  print <<EOF
--------------------------------------------------
  Hostname:   $_->{hostname}
  Score   :   $_->{score}
  Packages:
EOF
  ;
  foreach (@{$_->{pkgs}}) {
      print <<EOF
      Name : $_->{package}
      Score: $_->{score}
EOF
  }
}

