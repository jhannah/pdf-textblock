use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'PDF::TextBlock',
    AUTHOR              => 'Jay Hannah <jay@jays.net>',
    VERSION_FROM        => 'lib/PDF/TextBlock.pm',
    ABSTRACT_FROM       => 'lib/PDF/TextBlock.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'File::Temp'            => 0,
    },
    META_MERGE => {
         "meta-spec" => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'git@github.com:jhannah/pdf-textblock.git',
                 web  => 'https://github.com/jhannah/pdf-textblock.git',
             },
             bugtracker  => {
                 web  => 'https://github.com/jhannah/pdf-textblock/issues',
             },
         },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'PDF-TextBlock-*' },
);
