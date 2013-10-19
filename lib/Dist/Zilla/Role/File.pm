package Dist::Zilla::Role::File;
# ABSTRACT: something that can act like a file
use Moose::Role;

use Moose::Util::TypeConstraints;
use Try::Tiny;

use namespace::autoclean;

with 'Dist::Zilla::Role::StubBuild';

=head1 DESCRIPTION

This role describes a file that may be written into the shipped distribution.

=attr name

This is the name of the file to be written out.

=cut

has name => (
  is   => 'rw',
  isa  => 'Str', # Path::Class::File?
  required => 1,
);

=attr added_by

This is a string describing when and why the file was added to the
distribution.  It will generally be set by a plugin implementing the
L<FileInjector|Dist::Zilla::Role::FileInjector> role.

=cut

has added_by => (
  is => 'ro',
  writer => '_set_added_by',
  isa => 'Str',
);

=attr mode

This is the mode with which the file should be written out.  It's an integer
with the usual C<chmod> semantics.  It defaults to 0644.

=cut

my $safe_file_mode = subtype(
  as 'Int',
  where   { not( $_ & 0002) },
  message { "file mode would be world-writeable" }
);

has mode => (
  is      => 'rw',
  isa     => $safe_file_mode,
  default => 0644,
);

requires 'encoding';
requires 'content';
requires 'encoded_content';

sub _encode {
  my ($self, $text) = @_;
  my $enc = $self->encoding;
  if ( $enc eq 'bytes' ) {
    return $text;
  }
  else {
    require Encode;
    my $bytes =
    try { Encode::encode($enc, $text, Encode::FB_CROAK()) }
    catch { $self->_throw(encode => $_) };
    return $bytes;
  }
}

sub _decode {
  my ($self, $bytes) = @_;
  my $enc = $self->encoding;
  if ( $enc eq 'bytes' ) {
    return $bytes;
  }
  else {
    require Encode;
    my $text =
    try { Encode::encode($enc, $bytes, Encode::FB_CROAK()) }
    catch { $self->_throw(decode => $_) };
    return $text;
  }
}

sub _throw {
  my ($self, $op, $msg) = @_;
  my ($name, $added_by) = $self->$_ for qw/name added_by/;
  $self->log_fatal(
    "Could not $op $name on data from $added_by; error was: $msg"
  );
}

1;
