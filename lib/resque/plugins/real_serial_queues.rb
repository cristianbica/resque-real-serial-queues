require 'resque' unless defined?(Resque)

require "resque/plugins/version"

# Modifications to resque code go here
module Resque
  class Job

    # Given a queue name and a potential job (the one we are considering popping off the queue)
    # determine whether there is a worker currently working on a job with the same queue, class, and args
    # return true if we find an identical job, false if not
    def self.job_from_same_queue_is_currently_being_run(queue, job)
      return false unless job

      Worker.working.each do |worker|
        processing_job = worker.job
        next unless processing_job

        processing_queue = processing_job['queue']
        next unless processing_queue

        return true if processing_queue == queue
      end

      false
    end

    # Given a string queue name, returns an instance of Resque::Job
    # if any jobs are available. If not, returns nil.
    # This is a resque method overridden to first check
    # if the queue item has an identical job currently being worked on
    def self.reserve(queue)
      potential_job = Resque.peek(queue)
      return if job_from_same_queue_is_currently_being_run(queue, potential_job)
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
