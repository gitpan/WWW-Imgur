package WWW::Imgur;
use warnings;
use strict;
use Carp;
use MIME::Base64;
use LWP;
use JSON;

our $VERSION = 0.01;

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
    my ($file_name) = @_;
    if (! -f $file_name) {
        carp "Sorry, I can't find your image file '$file_name'";
        return;
    }
    my $input;
    if (! open $input, "<:raw", $file_name) {
        carp "Sorry, I can't open your image file '$file_name' because $!";
        return;
    }
    my $data;
    {
        local $/;
        $data = <$input>;
    }
    if (! close $input) {
        croak "Can't close '$file_name': $!";
    }
    if (length $data == 0) {
        carp "Your image file '$file_name' appears not to contain any data";
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
        carp "Please supply either a file name or a URL to upload";
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
        if ($self->verbose) {
            print "I am sending image data from a file '$image_path'.\n";
        }
        $image = read_image_file ($image_path);
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

WWW::Imgur - upload images to imgur.com

=head1 SYNOPSIS

    my $imgur = WWW::Imgur->new ();
    $imgur->key ('YoUrApIkEy');
    # Put an image on to the web site
    my $json = $imgur->upload ('fabulous.png')
        or die "Upload failed";
    # Delete an image
    $imgur->delete ('DelETEhasH');
        or die "Delete failed";

WWW::Imgur provides an interface to the image uploading and image
deletion APIs of the L<http://imgur.com/> image sharing website.

=head1 METHODS

=head2 new

    my $imgur = WWW::Imgur->new ({key => 'YoUrApIkEy',
                                  verbose => 1});

Create a new object.

=head2 key

    $imgur->key ('MyApiKEy');

Set the API key. You can get an API key at
L<http://imgur.com/register/api_anon> for an anonymous application, or
L<http://imgur.com/register/api_oauth> for a registered application.

=head2 verbosity

    # Turn on messages
    $imgur->verbosity (1);
    # Turn off messages
    $imgur->verbosity ();

Give a true value to get messages from the object telling you what it
is doing. Give a false or empty value to stop the messages.

=head2 upload

    $json = $imgur->upload ('fabulous.png');
    $json = $imgur->upload ('http://www.example.com/fabulous.png');

Upload an image to imgur.com. If it succeeds, it returns the JSON
message from imgur.com as plain text (it does not parse this message
into a Perl object). If it fails, it prints an error message on the
standard error and returns an undefined value.

If you want to view the contents of C<$json>, try, for example

    use JSON;
    use Data::Dumper;
    my $json = $imgur->upload ('nuts.png');
    print Dumper (json_decode ($json));

See examples/upload.pl for a full example.

There is another argument to upload where you can add more
options. Currently there are two options, "caption" and "title".

    my $json = $imgur->upload ('sharon-stone.jpeg',
                           {
                               caption => 'Sharon Stone stoned again',
                               title => 'Sharon Stone gathers no moss',
                           });

However, although the values you send are sent back in the JSON
response you get from the site, these don't appear to do anything.

=head2 delete

     $imgur->delete ('ImageDeleteHASH');

Delete an image from imgur.com. You need a key called the
"deletehash", which is one of the parts of the JSON response from the
L</upload> method.

If you try to delete an image which has already been deleted, it seems
to respond with a "400 Bad Request" error.

=head2 agent

     $imgur->agent ('MyScript.pl');

Set the user agent string of the agent which makes the request. The
default value of the user agent string is "WWW::Imgur".

=head1 SEE ALSO

L<Image::Imgur> is an alternative upload module for imgur.com.

=head1 AUTHOR

Ben Bullock, <bkb@cpan.org>

=head1 LICENCE

You can copy, modify and redistribute WWW::Imgur under the Perl
Artistic Licence or the GNU General Public Licence.

=cut

