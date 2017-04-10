#!/usr/bin/perl
# (C) kreon 2016
use strict;
use warnings;
use lib 'perl5';
use HTTP::Tiny;
use DBI;
use JSON;
use constant VULNERS_AUDIT_API => 'http://vulners.com/api/v3/audit/audit/';
use constant VULNERS_ID_API    => 'http://vulners.com/api/v3/search/id/';
use constant DB                => 'dbi:Pg:dbname=pkgs';

our %VULNS;
our $dbh;
our %pkgs = ();
# 0. connect to DB
$dbh = DBI->connect( DB, "", "", { RaiseError => 1, AutoCommit => 0 } );

# get all OS variations
my @os = get_os();
# for each OS get all packages and ask vulners for its vulnerabilities
foreach my $os (@os) {
    eval {
        my ( $o, $ver ) = split( / /, $os );
        my $res = HTTP::Tiny->new->request(
            'POST',
            VULNERS_AUDIT_API,
            {   headers => { 'Content-Type' => 'application/json' },
                content => JSON->new->encode(
                    {   os      => $o,
                        version => $ver,
                        package => [ get_packages($os) ]
                    }
                )
            }
        );
        if ( !$res->{success} ) {
            die "HTTP Error: $res->{content}";
        }
        my $data  = JSON->new->decode( $res->{content} );
        my $vulns = $data->{data}->{packages};
        return undef unless defined $vulns;
        foreach ( keys %$vulns ) {
            my $o = $vulns->{$_};
            if ( defined( $pkgs{$_} ) ) {
                $VULNS{ $pkgs{$_} } = [ keys %$o ];
            }
        }
    };
    print $@ if $@;
}

# Now get info on each vuln ID ( CESA, USN, etc ) ...
my @result;
my $res = HTTP::Tiny->new->request(
    'POST',
    VULNERS_ID_API,
    {   headers => { 'Content-Type' => 'application/json' },
        content => JSON->new->encode( { id => [ map {@$_} values %VULNS ] } )
    }
);

if ( !$res->{success} ) {
    die "HTTP Error: $res->{content}";
}
my $data = JSON->new->decode( $res->{content} );
foreach ( values %{ $data->{data}->{documents} } ) {
    push @result,
        {
        id          => $_->{id},
        cvss_score  => $_->{cvss}->{score},
        cvss_vector => $_->{cvss}->{vector},
        description => $_->{description},
        cvelist     => join( ', ', @{ $_->{cvelist} } ),
        };
}

# Insert the data to DB
eval {
    $dbh->do( "DELETE FROM v2p",     undef );
    $dbh->do( "DELETE FROM vulners", undef );
    # insert prepared data to vulners table
    foreach (@result) {
        $dbh->do(
            "INSERT INTO vulners (id, cvss_score, cvss_vector, description, cvelist) VALUES (?,?,?,?,?)",
            undef,
            $_->{id},
            $_->{cvss_score},
            $_->{cvss_vector},
            $_->{description},
            $_->{cvelist}
        );
    }
    # and link pkg and vuls into v2p
    foreach my $pkg_id ( keys %VULNS ) {
        foreach my $vuln_id ( @{ $VULNS{$pkg_id} } ) {
            $dbh->do( "INSERT INTO v2p(pkg_id,vuln_id) VALUES(?,?)",
                undef, $pkg_id, $vuln_id );
        }
    }
};
$dbh->rollback and die "Error $@" if $@;
$dbh->commit;
# All done
1;

### SUBS ####
sub get_os {
    my @os;
    my $sth = $dbh->prepare("SELECT DISTINCT os FROM hosts");
    $sth->execute();
    while ( my ($os) = $sth->fetchrow_array ) {
        push @os, $os;
    }
    return @os;
}

sub get_packages {
    my $os = shift;
    my $sth
        = $dbh->prepare(
        "select DISTINCT p.id,p.name FROM pkg p RIGHT JOIN hosts h ON (p.id=ANY(h.pkg_id)) WHERE h.os=?"
        );
    $sth->execute( ($os) );
    my @pkgs;
    while ( my ( $id, $name ) = $sth->fetchrow_array ) {
        $pkgs{$name} = $id;
        push @pkgs, $name;
    }
    return @pkgs;
}
