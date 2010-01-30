package Capture::System;

use strict;
use warnings;

our $VERSION = '0.01';

# TODO: needs docs

# TOOD: this module should be tested

sub _new {
  my $class = shift;
  my $opts = _default_opts();
  if(ref($_[0]) eq "HASH") {
    $opts = shift;
  }
  my @cmd = @_;
  my $self = {};
  bless $self, $class;
  @{$self->{cmd}} = @cmd;
  $self->{opts} = $opts;
  $self->_system();
  return $self;
}

# TODO: set defaults?
sub _default_opts {
  return {};
}

use IO::Pipe;

use POSIX qw/dup2/;

use Carp;

# TODO: support "tee" as well
# TODO: check for incorrect opts

sub _system {
  my $self = shift;
  my $stderr = IO::Pipe->new();
  my $stdout = IO::Pipe->new();
  my $merged = IO::Pipe->new();
  my ($capture_merged, $capture_stdout, $capture_stderr) = (0, 0, 0);
  if($self->_get_opt("stderr") eq "capture") {
    $capture_stderr = 1;
  }
  if($self->_get_opt("merged") eq "capture") {
    $capture_merged = 1;
  }
  if($self->_get_opt("stdout") eq "capture") {
    $capture_stdout = 1;
  }

  if(($capture_stdout + $capture_stderr) > 0 && $capture_merged > 0) {
    die("Can't capture individual outputs and merge them at the same time");
  }
  my $pid;
  $pid = fork();
  if($pid == 0) {
    $stderr->writer();
    $stdout->writer();
    $merged->writer();

    if($capture_stderr) {
      dup2(fileno($stderr), fileno(STDERR));
    }

    if($capture_stdout) {
      dup2(fileno($stdout), fileno(STDOUT));
    }

    if($capture_merged) {
      dup2(fileno($merged), fileno(STDOUT));
      dup2(fileno($merged), fileno(STDERR));
    }

    exec(@{$self->{cmd}});
    exit;
  }
  $stderr->reader();
  $stderr->blocking(0);
  $stdout->reader();
  $stdout->blocking(0);
  $merged->reader();
  $merged->blocking(0);
  waitpid $pid, 0;
  my $retval = $? >> 8;
  if($capture_stderr) {
    $self->{stderr} = join '', <$stderr>;
  }
  if($capture_stdout) {
    $self->{stdout} = join '', <$stdout>;
  }
  if($capture_merged) {
    $self->{merged} = join '', <$stdout>;
  }
  $self->{status} = $retval;
  $self->{pid} = $pid;
}

sub _new_from_hash {
  my $class = shift;
  my $self = shift;
  bless $self, $class;
  return $self;
}

sub status {
  my $self = shift;
  return $self->{status};
}

sub stderr {
  my $self = shift;
  return $self->_captured("stderr");
}

# "sub ssh" should allow passthrough, capture, and/or tee of both
# stderr and stdout. it should also allow merging for capture and tee.

sub stdout {
  my $self = shift;
  return $self->_captured("stdout");
}

sub _get_opt {
  my $self = shift;
  my $name = shift;
  if(!defined($self->{opts}->{$name})) {
    return "";
  }
  return $self->{opts}->{$name};
}

sub _captured {
  my $self = shift;
  my $name = shift; # stderr, stdout, merged
  if(! $self->_get_opt($name) eq "capture") { # TODO: this croak fails. use test-driven programming for this one ;).
    local $Carp::CarpLevel = 1;
    croak("Didn't capture this type of output: $name");
  }
  return $self->{$name};
}

sub pid {
  my $self = shift;
  return $self->{pid};
}

sub merged {
  my $self = shift;
  return $self->_captured("merged");
}

1;
