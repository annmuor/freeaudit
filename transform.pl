#!/usr/bin/perl
# (C) kreon 2017
use strict;
use warnings;
use JSON;
use DBI;
use constant DB => 'dbi:Pg:dbname=pkgs';

# 0. create connection
my $dbh
    = DBI->connect( DB, "", "", { RaiseError => 1, AutoCommit => 0 } );

# 1. read from stdin and parse
my $data = JSON->new->decode( join( "", <STDIN> ) );

# if data == array parse foeach
if ( ref($data) eq "ARRAY" ) {
    foreach (@$data) {
        parse_host($_);
    }
}
else {
    parse_host($data);
}

# Done
1;

### SUBS ###
sub parse_host {
    $_ = shift;

    # do parse packages
    my ( $hostname, $os, @pkgs )
        = ( $_->{hostname}, $_->{os}, @{ $_->{pkgs} } );
    my @pkgids;
    eval {
        foreach (@pkgs) {
            my $sth = $dbh->prepare("SELECT id FROM pkg WHERE name=?");
            $sth->execute( ($_) );
            if ( my ($id) = $sth->fetchrow_array ) {
                push @pkgids, int($id);
            }
            else {
                $dbh->do( "INSERT INTO pkg (name) VALUES(?)", undef, $_ );
                push @pkgs, $_;
            }
        }
    };
    $dbh->rollback and die "$@" if $@;
    $dbh->commit;

    # do parse host
    eval {
        my $sth = $dbh->prepare("SELECT os FROM hosts WHERE hostname=?");
        $sth->execute( ($hostname) );
        if ( my ($os2) = $sth->fetchrow_array ) {
            if ( lc($os2) ne lc($os) ) {
                $dbh->do( "UPDATE hosts SET os=? WHERE hostname=?",
                    undef, $os, $hostname );
            }
        }
        else {
            $dbh->do( "INSERT INTO hosts (hostname, os) VALUES(?, ?)",
                undef, $hostname, $os );
        }
    };
    $dbh->rollback and die "$@" if $@;
    $dbh->commit;

    # do set packages
    eval {
        $dbh->do( "UPDATE hosts SET pkg_id=? WHERE hostname=?",
            undef, [@pkgids], $hostname );
    };
    $dbh->rollback and die "$@" if $@;
    $dbh->commit;
}
