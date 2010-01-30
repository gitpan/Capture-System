use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Capture::System',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version        => '0.01',
    dist_abstract       => 'Run a program and capture its output in different ways.',
    requires => {},
    build_requires => {},
    add_to_cleanup      => [ 'Capture-System-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
