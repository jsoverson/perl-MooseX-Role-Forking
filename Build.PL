use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MooseX::Role::Forking',
    license             => 'perl',
    dist_author         => q{Jarrod Overson <jsoverson+cpan@googlemail.com>},
    dist_version_from   => 'lib/MooseX/Role/Forking.pm',
    dist_abstract       => 'Moose role for forking',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'MooseX-Role-Forking-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
