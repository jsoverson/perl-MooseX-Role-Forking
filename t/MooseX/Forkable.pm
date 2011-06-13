package t::MooseX::Forkable;

use Test::Class;
use base 'Test::Class';
use Test::More;

use MooseX::Forkable;

sub test_create : Tests {
   my $job = MooseX::Forkable->new(sub {
      print "this will be a forked job\n";
      return shift;
   });

   ok($job->abandon_filehandles);

   ok($job->run(1));

   sleep(1);

   ok($job->has_ended);

   is($job->exit_code, 1);
}

1;
