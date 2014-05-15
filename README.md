# Resque::Plugins::RealSerialQueues

This plugin modifies [Resque's](https://github.com/resque/resque) job reservation process to first check if there is another job 
from the same queue as the potential job currently being processed by one of your workers and tells the worker to check again after its sleep cycle.

It is primarily meant to be used to queue long running background jobs across multiple queues in conjunction with something like [resque-scheduler](https://github.com/resque/resque-scheduler)

A key difference between this and [resque-lonely_job](https://github.com/wallace/resque-lonely_job) is that the queue is not touched when we check to see if we can process the job.  However, because we must check all the workers
currently working on the system this plugin may not scale well to large numbers of workers.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-real-serial-queues'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-real-serial-queues

## Usage
  Just load up plugin somewhere in your project's initializers:

    require 'resque_real_serial_queues'

  In rails adding

    resque_real_serial_queues.rb

  to your 

    config/initializers

  directory with the above line should do the trick.

  Note that this will currently affect all queues
## Contributing

1. Fork it ( https://github.com/[my-github-username]/resque-real-serial-queues/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
