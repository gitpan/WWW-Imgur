use ExtUtils::MakeMaker;

my $pm = 'lib/WWW/Imgur.pm';
my $repo = 'https://github.com/benkasminbullock/WWW-Imgur';

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
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    LICENSE => 'perl',
);
