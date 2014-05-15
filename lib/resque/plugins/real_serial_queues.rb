require 'resque' unless defined?(Resque)

require "resque/plugins/version"

# Modifications to resque code go here
module Resque
  class Job

    # Given a queue name and a potential job (the one we are considering popping off the queue)
    # determine whether there is a worker currently working on a job with the same queue, class, and args
    # return true if we find an identical job, false if not
    def self.same_job_in_same_queue_currently_being_run(queue, job)
      return false unless job
      puts "---- now checking for already running jobs in queue #{queue} of class #{job['class']} ---"
      job_class = job['class']
      job_args  = job['args']

      Worker.working.each do |worker|
        queue_matches = false
        class_matches = false
        args_match    = false

        processing_job = worker.job

        processing_queue = processing_job['queue']
        processing_class = processing_job['payload']['class']
        processing_args  = processing_job['payload']['args']

        queue_matches = processing_queue == queue
        class_matches = processing_class == job_class
        
        processing_args.each_with_index do |arg, i|
          next unless arg && arg[i]
          args_match = arg == job_args[i]
          break if args_match
        end
        puts "found a matching job, aborting reserve!" if queue_matches && class_matches && args_match
        return true if queue_matches && class_matches && args_match
      end

      false
    end

    # Given a string queue name, returns an instance of Resque::Job
    # if any jobs are available. If not, returns nil.
    # This is a resque method overridden to first check
    # if the queue item has an identical job currently being worked on
    def self.reserve(queue)
      # Hack.  Find a way not to do this
      return if queue == '*'
      potential_job = Resque.peek(queue)
      return if same_job_in_same_queue_currently_being_run(queue, potential_job)
      return unless payload = Resque.pop(queue)
      new(queue, payload)
    end
  end
end

# if we add any actual method extensions add them here
module Resque # :nodoc:
  module Plugins # :nodoc
    module RealSerialQueues
    end
  end
end
