use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'WWW::Imgur',
    VERSION_FROM => 'lib/WWW/Imgur.pm',
    PREREQ_PM => {
        JSON => 0,
        'MIME::Base64' => 0,
        LWP => 0,
        Carp => 0,
    },
);
