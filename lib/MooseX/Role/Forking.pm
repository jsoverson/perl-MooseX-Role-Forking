package MooseX::Role::Forking;

use POSIX qw( :sys_wait_h );
use Scalar::Util 'refaddr';
use Carp;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
   as_is => [ 'sleep_undisturbed' ],
);

use Moose::Role;

our $VERSION = '0.01';

requires 'job';

has forked_pid    => ( is => 'ro', writer => '_forked_pid' );
has has_ended     => ( is => 'ro', writer => '_has_ended' );
has is_registered => ( is => 'ro', writer => '_is_registered' );
has address       => ( is => 'ro', writer => '_address' );
has id            => ( is => 'ro', writer => '_id' );
has exit_code     => ( is => 'ro', writer => '_exit_code' );
has _abandon_filehandles   => ( is => 'rw' );
has arguments     => ( is => 'rw', reader => 'get_arguments', writer => 'set_arguments' );

sub sleep_undisturbed {
   my $seconds = shift;

   my $seconds_slept = 0;
   while ($seconds_slept <= $seconds) {
      $seconds_slept += sleep($seconds - $seconds_slept);
   }
   return $seconds_slept;
}

{
   my $PARENTS = {};
   my $CHILDREN = {};

   $SIG{CHLD} = sub {
      while ((my $pid = waitpid( -1, WNOHANG)) > 0) {
         _cleanup_handler($pid);
      }
   };

   sub _cleanup_handler {
      my $pid = shift;
      my $parent_id = $CHILDREN->{$pid};
      my $parent = $PARENTS->{$parent_id};

      return if not $parent; #we've already been destroyed

      $parent->_has_ended(1);
      $parent->_exit_code($? >> 8);
      delete $CHILDREN->{$pid};
   }

   sub run {
      my $self = shift;

      $self->_register;

      if ($self->forked_pid && not $self->has_ended) {
         carp 'Previous child (' . $self->forked_pid . ') has not ended, can not start another.';
         return;
      }

      my $pid = fork;

      if ($pid) {
         $self->_forked_pid($pid);
         $self->_register_child;
         return $pid;
      }

      if ($self->_abandon_filehandles) {
         open STDIN, '/dev/null';
         open STDOUT, '/dev/null';
         open STDERR, '/dev/null';
      }

      my $rv;

      if (@{$self->arguments || []} > 0) {
         if (@_) {
            carp 'Warning : "arguments" attribute set while job started with passed '.
                 'parameters, set arguments always take precedence. Maybe you forgot to ->reset()?';
         }
         $rv = $self->job(@{$self->arguments});
      } else {
         $rv = $self->job(@_);
      }

      $self->_has_ended(1);
      
      exit($rv);
   }

   sub abandon_filehandles {
      my $self = shift;

      $self->_abandon_filehandles(1);
   }

   sub reset {
      my $self = shift;
      
      delete $CHILDREN->{$self->forked_pid};
      $self->_forked_pid(undef);
      $self->_has_ended(0);
      $self->_exit_code(undef);
      $self->set_arguments(undef);
   }

   sub kill_job {
      my $self = shift;
      my $signal = shift || 15;

      return 1 if $self->has_ended;

      my $num_signalled = kill ($signal, $self->forked_pid);
      sleep(1); # give a second to wait for SIGCHLD

      if ($num_signalled) {
         my $num_signalled_after = kill (0, $self->forked_pid);
         if ($num_signalled_after) {
            # process never died. will need special handling
            return 0;
         } else {
            return 1;
         }
      } else {
         # could not signal pid, maybe died or under a different user?
         return 1;
      }
   }

   sub arguments {
      my $self = shift;
      my @args = @_;

      if (@args) {
         return $self->set_arguments(\@args);
      } else {
         return wantarray ? @{$self->get_arguments} : $self->get_arguments;
      }
   }

   sub _register {
      my $self = shift;
      
      return if $self->is_registered;

      $self->_address(refaddr $self);
      $self->_id($$ . '-' . $self->address);
      $self->_is_registered(1);
      $PARENTS->{$self->id} = $self;

      return 1;
   }

   sub _register_child {
      my $self = shift;

      my $pid = $self->forked_pid;

      $CHILDREN->{$pid} = $self->id();
   }

   sub DESTROY {
      my $self = shift;
      return if not $self->id;
      
      delete $PARENTS->{$self->id};
   }

}

1;
__END__

=head1 NAME

MooseX::Role::Forking 

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Jarrod Overson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
