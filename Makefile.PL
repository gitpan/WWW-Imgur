use ExtUtils::MakeMaker;

my $pm = 'lib/WWW/Imgur.pm';

WriteMakefile (
    NAME => 'WWW::Imgur',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pm,
    PREREQ_PM => {
        JSON => 0,
        'MIME::Base64' => 0,
        LWP => 0,
        Carp => 0,
    },
);
