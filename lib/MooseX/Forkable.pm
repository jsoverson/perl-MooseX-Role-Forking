package MooseX::Forkable;

use Moose;

with 'MooseX::Role::Forking';

has code => ( is => 'rw', isa => 'CodeRef', default => sub{} );

around 'new' => sub {
   my $NEXT = shift;
   my $CLASS = shift;

   if (ref $_[0] eq 'CODE') {
      return $CLASS->$NEXT( code => shift );
   } else {
      return $CLASS->$NEXT( @_ );
   }
};

sub job {
   my $self = shift;

   return $self->code->(@_);
}

1;
