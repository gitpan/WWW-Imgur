package WWW::Imgur;
use warnings;
use strict;
use Carp;
use MIME::Base64;
use LWP;
use JSON;

our $VERSION = 0.04;

# The imgur API url used.

my $api_url = 'http://api.imgur.com/2';

# Public.

sub new
{
    my ($package, $options) = @_;
    my $self = {};
    bless $self;
    if ($options) {
        if ($options->{key}) {
            $self->key ($options->{key});
        }
        if ($options->{verbose}) {
            $self->verbosity ($options->{verbose});
        }
        if ($options->{agent}) {
            $self->agent ($options->{agent});
        }
    }
    return $self;
}

# Public.

sub agent
{
    my ($self, $agent) = @_;
    if ($agent) {
        $self->{user_agent} = $agent;
    }
    if ($self->{user_agent}) {
        return $self->{user_agent};
    }
    return __PACKAGE__;
}

# Private.

sub key
{
    my ($self, $key) = @_;
    if ($key) {
        if ($self->{api_key}) {
            carp __PACKAGE__, ": deleting a previous API key";
        }
        $self->{api_key} = $key;
    }
    return $self->{api_key};
}

# Public.

sub verbosity
{
    my ($self, $verbosity) = @_;
    $self->{verbosity} = $verbosity;
}

# Private.

sub verbose
{
    my ($self) = @_;
    return $self->{verbosity};
}

# Private.

sub read_image_file
{
    my ($image_path, $verbose) = @_;
    my $data;
    if (ref $image_path eq 'SCALAR') {
        $data = $$image_path;
    }
    else {
        if ($verbose) {
            print "I am sending image data from a file '$image_path'.\n";
        }
        if (! -f $image_path) {
            carp "Sorry, I can't find your image file '$image_path'";
            return;
        }
        my $input;
        if (! open $input, "<:raw", $image_path) {
            carp "Sorry, I can't open your image file '$image_path' because $!";
            return;
        }
        {
            local $/;
            $data = <$input>;
        }
        if (! close $input) {
            croak "Can't close '$image_path': $!";
        }
    }
    if (length $data == 0) {
        carp "Your image appears not to contain any data";
        return;
    }
    my $base_64_data = encode_base64 ($data);
    return $base_64_data;
}

# Public.

sub upload 
{
    my ($self, $image_path, $options) = @_;
    if (! $image_path) {
        carp "Please supply either a file name, a reference to image data, or a URL to upload";
        return;
    }
    my $image;
    if ($image_path =~ m!https?://!) {
        if ($self->verbose) {
            print "I am sending a URL '$image_path'.\n";
        }
        $image = $image_path;
    }
    else {
        $image = read_image_file ($image_path, $self->verbose);
    }
    if (! $image) {
        carp "I am aborting the upload";
        return;
    }
    if ($self->verbose) {
        print "I am going to upload '$image_path'.\n";
    }
    return $self->really_upload ($image, $options);
}

# Private.

sub make_agent
{
    my ($self) = @_;
    return LWP::UserAgent->new ($self->agent);
}

# Public.

sub delete
{
    my ($self, $deletehash) = @_;
    if (! $deletehash) {
        carp "You need to supply a parameter, 'deletehash'";
        return;
    }
    if ($self->verbose) {
        print "I am trying to delete something using a parameter '$deletehash'.\n";
    }
    my $agent = $self->make_agent ();
    my $delete_url = "$api_url/delete/$deletehash.json";
    my $response = 
        $agent->get (
            $delete_url,
            'key' => $self->key (),
        );
    if (! $response->is_success) {
        carp "Delete failed with an error " .
            $response->status_line;
        return;
    }
    if ($self->verbose) {
        print "Delete request succeeded.\n";
    }
    my $imgur_message_json = $response->content;
    my $imgur_message = decode_json ($imgur_message_json);
    if ($imgur_message->{delete} &&
        $imgur_message->{delete}->{message} eq 'Success') {
        return $imgur_message;
    }
    else {
        carp "Delete failed with a JSON message '$imgur_message_json'";
        return;
    }
}

# Private

sub really_upload
{
    my ($self, $image, $options) = @_;
    if (! $image) {
        croak "Nothing to upload";
    }
    if (! $self->key ()) {
        carp "Please supply an API key";
        return;
    }
    my $agent = $self->make_agent ();
    my @image_data = 
        (
            'image' => $image,
            'key' => $self->key (),
        );
    for my $option (qw/title caption/) {
        if ($options->{$option}) {
            push @image_data, ($option => $options->{$option});
        }
    }
    my $response = 
        $agent->post (
            "$api_url/upload.json",
            \@image_data,
        );
    if (! $response->is_success) {
        carp "Upload failed with an error " .
            $response->status_line;
        return;
    }
    if ($self->verbose) {
        print "Upload succeeded.\n";
    }
    my $imgur_message_json = $response->content;
    return $imgur_message_json;
}

1;

__END__

=head1 NAME

WWW::Imgur - upload images to imgur.com via deprecated version 2 API

=head1 SYNOPSIS

    my $imgur = WWW::Imgur->new ();
    $imgur->key ('YoUrApIkEy');
    # Put an image on to the web site
    my $json = $imgur->upload ('fabulous.png')
        or die "Upload failed";
    # Delete an image
    $imgur->delete ('DelETEhasH')
        or die "Delete failed";

=head1 DESCRIPTION

WWW::Imgur provides an interface to the deprecated version 2 image
uploading and image deletion APIs of the L<http://imgur.com/> image
sharing website. See L</API version 2 only> below.

See L<http://api.imgur.com/> for details of the Imgur API. The
documentation for the version 2 API which this module uses has been
removed from the website.

=head1 METHODS

=head2 new

    my $imgur = WWW::Imgur->new ();

    my $imgur = WWW::Imgur->new ({key => 'YoUrApIkEy',
                                  verbose => 1});

Create a new object. You can supply an argument of a hash reference
containing the following keys:

=over

=item key => 'YoUrApIkEy'

Set the API key. Equivalent to calling the L</key> method with an argument.

=item verbose => 1

Turn on or off non-error messages from the module. Equivalent to
calling the L</verbosity> method with an argument.

=item agent => 'Incredible User Agent'.

This option sets the user agent string. It is equivalent to calling
the L</agent> method with an argument.

=back

=head2 key

    $imgur->key ('MyApiKEy');

This method sets the value of the API key to whatever you give as an
argument. You can get an API key at
L<http://imgur.com/register/api_anon> for an anonymous application, or
L<http://imgur.com/register/api_oauth> for a registered
application. However, WWW::Imgur doesn't handle the OAuth
interface. See L</No OAuth>.

=head2 verbosity

    # Turn on messages
    $imgur->verbosity (1);
    # Turn off messages
    $imgur->verbosity ();

Give a true value to get messages from the object telling you what it
is doing. Give a false or empty value to stop the messages.

=head2 upload

    $json = $imgur->upload (\$image_data);
    $json = $imgur->upload ('fabulous.png');
    $json = $imgur->upload ('http://www.example.com/fabulous.png');

Upload an image to imgur.com. If it succeeds, it returns the JSON
message from imgur.com as plain text (it does not parse this message
into a Perl object). If it fails, it prints an error message on the
standard error and returns an undefined value.

The argument can either be 

=over

=item actual image data,

in which case you should pass it as a scalar reference, as in
C<\$image_data> in the first line of the example above,

=item the file name of an image file,

as in C<'fabulous.png'> in the second line of the example above, or 

=item the URL of an image,

as in C<'http://www.example.com/fabulous.png'> in the third line of
the example above. Imgur's documentation referred to this as "Image
Sideloading".

The URL is passed to imgur.com, so it needs to be one which
is accessible to the imgur.com server, not a local or private one.

=back

WWW::Imgur does not parse the JSON for you. See 
L</No parsing of JSON>.
If you want to view the contents of C<$json>, try, for example

    use JSON;
    use Data::Dumper;
    my $json = $imgur->upload ('nuts.png');
    print Dumper (json_decode ($json));

See the example in the file C<examples/upload.pl> of the WWW::Imgur
distribution for a full example.

There is an optional second argument to the upload method. You pass a
hash reference containing options. Currently there are two options,
"caption" and "title".

    my $json = $imgur->upload ('sharon-stone.jpeg',
                           {
                               caption => 'Sharon Stone is a stone gas',
                               title => 'Sharon Stone gathers no moss',
                           });

However, although the values you send are sent back in the JSON
response you get from the site, these don't seem to actually show up
anywhere on the Imgur website itself.

=head2 delete

     $imgur->delete ('ImageDeleteHASH');

This method deletes an image from imgur.com. It takes one argument, a
key called the "deletehash", which is one of the parts of the JSON
response from the L</upload> method.

If it succeeds, it returns the message from Imgur. If it fails, it
prints a message on STDERR and returns an undefined value.

If you try to delete an image which has already been deleted, Imgur
seems to respond with a "400 Bad Request" error.

=head2 agent

     $imgur->agent ('MyScript.pl');

Given an argument, this sets the user agent string of the agent which
makes the request. The default value of the user agent string is
"WWW::Imgur".

Without an argument, it returns what the user agent string is
currently set to.

=head1 DEPENDENCIES

This module uses L<MIME::Base64> to encode the image data to send to
Imgur, L<JSON> to decode the return message in the L</delete> method,
L<LWP> to communicate with imgur.com, and L<Carp> to report errors.

=head1 BUGS

The following features are not implemented.

=over

=item No OAuth

There is no support for the OAuth interface for registered
applications.

=item No tests

The test suite doesn't do anything except test this module for
compilation. Please get an API key and then use the example scripts to
test the module to make sure it works correctly against the actual
Imgur API.

=item No XML

There is no support for the XML API.

=item No image stats

The Imgur API contains a method to get information about an image, but
this module doesn't have a way to access that.

=item No parsing of JSON

The successful return value of the L</upload> method is the JSON text
which Imgur sends back, unparsed.

=item API version 2 only

This module is for the now-deprecated imgur version 2 API. The current
version of imgur's API as of December 2012 is version 3. The author of
WWW::Imgur does not intend to go on using the imgur service due to
changes in terms and conditions. Those who would like to upgrade this
to the version 3 API are requested to contact the current author and
take over the module's development.

See also L<http://blogs.perl.org/users/ben_bullock/2012/12/notice---wwwimgur-end-of-life.html>.

=back

=head1 SEE ALSO

L<Image::Imgur> is an alternative module for imgur.com. It uses the
XML version of the API rather than the JSON one which WWW::Imgur uses,
and it depends on the L<Moose> module. It uses an older version of the
Imgur API. The version on CPAN at the time of writing (22 March 2011)
has a method to upload image files, but does not have one to delete
images or to upload image data from memory.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 LICENCE

You can copy, modify and redistribute WWW::Imgur under the Perl
Artistic Licence or the GNU General Public Licence.

=cut

