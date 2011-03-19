#!/usr/bin/perl
use warnings;
use strict;
use WWW::Imgur;
use JSON;
use Data::Dumper;

# Upload example

my $imgur = WWW::Imgur->new ();
$imgur->verbosity (1);
$imgur->key ('putyourkeyhere');
my $file = 'guffin.png';
my $json = $imgur->upload (
    $file, {
        caption => "It's a guffin",
        title => "GUFFINS ARE MARVELLOUS"
    }
);
print "$json\n";
my $decoded = decode_json ($json);
print Dumper ($decoded);
