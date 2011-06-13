package t::MooseX::Role::Forking;

use Test::More;
use MooseX::Forkable;

use base 'Test::Class';

sub test_load_implementer : Tests {
   my $job = new Test::Forkable;

   ok (blessed $job);

   $job->abandon_filehandles;

   ok ($job->run);

   my $seconds_slept = Test::Forkable::sleep_undisturbed (1);

   ok ($seconds_slept > 0);

   ok ($job->has_ended);

   is ($job->exit_code, 22);

   $job->reset;

   ok (not $job->has_ended);
   
   ok (not $job->exit_code);

   ok ($job->run(42));

   sleep(1);

   ok($job->has_ended);

   is($job->exit_code, 42);

   $job = Test::Forkable->new;

   $job->abandon_filehandles(); #comment out if you want to see an argument warning;

   ok (not $job->has_ended);
   
   ok (not $job->exit_code);

   ok (not $job->arguments);

   ok ($job->arguments((73,123)));

   is (@{$job->arguments}, @{[73,123]});

   ok ($job->run('ignored'));

   sleep(1);

   ok($job->has_ended);

   is($job->exit_code, 73);
}

sub test_kill_job : Tests {
   my $code = sub {
      sleep 20;
   };
   
   my $job = MooseX::Forkable->new($code);

   $job->run;

   sleep 1;
   
   ok(not $job->has_ended);
   
   ok($job->kill_job);

   ok($job->has_ended);
}

sub test_multiple_objects : Tests {
   my @jobs;

   my $num_jobs = 10;

   close STDOUT;
   open STDOUT, '>', undef or die "Can't open STDOUT into temporary file : $!";

   push (@jobs, new Test::Forkable) for (1..$num_jobs);

   my $i = 0;

   foreach my $job (@jobs) {
      $job->abandon_filehandles if ++$i % 2;
      $job->run(int (rand 50));
   }

   my $has_ended = 0;

   while (!$has_ended) {
      foreach my $job (@jobs) {
         $has_ended = $job->has_ended;
         last if not $has_ended;
      }
      sleep 1 unless $has_ended;
   }

   seek (STDOUT, 0, 0);

   my @stdout = <STDOUT>;

   is (scalar @stdout, int ($num_jobs / 2));
}

package Test::Forkable;
use Moose;

with 'MooseX::Role::Forking';

sub job {
   my $self = shift;
   my $exit_code = shift || 22;

   print "This is my job, i exit with $exit_code\n";

   return $exit_code;
}
