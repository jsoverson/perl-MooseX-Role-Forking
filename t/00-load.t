#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Role::Forking' );
}

diag( "Testing MooseX::Role::Forking $MooseX::Role::Forking::VERSION, Perl $], $^X" );
