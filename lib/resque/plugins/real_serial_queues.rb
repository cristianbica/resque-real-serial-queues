require 'resque' unless defined?(Resque)

require "resque/plugins/version"

# Modifications to resque code go here
module Resque
  class Job

    # Given a queue name
    # determine whether there is a worker currently working on a
    # job from the same queue
    # return true
    def self.job_from_same_queue_is_currently_being_run?(queue)
      Worker.working.each do |worker|
        processing_job = worker.job
        next unless processing_job

        processing_queue = processing_job['queue']
        next unless processing_queue

        return true if processing_queue == queue
      end

      false
    end

    def self.is_queue_serial?(queue)
      return false if Resque::Plugins::RealSerialQueues.non_serial_queues.include?(queue)
      return true  if Resque::Plugins::RealSerialQueues.serial_queues.include?(queue)
      return Resque::Plugins::RealSerialQueues.default_queue_type==:serial
    end

    # Given a string queue name, returns an instance of Resque::Job
    # if any jobs are available. If not, returns nil.
    # This is a resque method overridden to first check
    # if there is another job from the queue being checked currently
    # being worked on.  This check can be bypassed by setting
    # non_serial_queues via Resque::Plugins::RealSerialQueues.config=
    # in your Resque config
    def self.reserve(queue)
      return if is_queue_serial?(queue) and job_from_same_queue_is_currently_being_run?(queue)
      return unless payload = Resque.pop(queue)
      new(queue, payload)
    end
  end
end

# if we add any actual method extensions add them here
module Resque
  module Plugins
    module RealSerialQueues
      class InvalidConfigurationError < StandardError; end

      class << self
        attr_accessor :default_queue_type
        attr_accessor :non_serial_queues
        attr_accessor :serial_queues
      end

      def self.config=(config_hash)
        if config_hash
          self.check_if_config_is_valid(config_hash)
          self.non_serial_queues  = config_hash[:non_serial_queues]||[]
          self.serial_queues      = config_hash[:serial_queues]||[]
          self.default_queue_type = (config_hash[:default_queue_type]||:serial).to_sym
        end
      end

      private

      def self.check_if_config_is_valid(config_hash)
        fail(
          InvalidConfigurationError,
          'Something is wrong with your config file.  Sorry...'
        ) if !config_hash.is_a?(Hash)

        fail(
          InvalidConfigurationError,
          'Please specify non-serial queue names in an array ' +
          '(or collection if you are using YAML: http://yaml4r.' +
          'sourceforge.net/doc/page/collections_in_yaml.htm)'
        ) if config_hash[:non_serial_queues] && !config_hash[:non_serial_queues].is_a?(Array)

        fail(
          InvalidConfigurationError,
          'Please specify serial queue names in an array ' +
          '(or collection if you are using YAML: http://yaml4r.' +
          'sourceforge.net/doc/page/collections_in_yaml.htm)'
        ) if config_hash[:serial_queues] && !config_hash[:serial_queues].is_a?(Array)

        fail(
          InvalidConfigurationError,
          'Please specify serial queue names in an array ' +
          '(or collection if you are using YAML: http://yaml4r.' +
          'sourceforge.net/doc/page/collections_in_yaml.htm)'
        ) if config_hash[:default_queue_type] && !%w(serial parallel).include?(config_hash[:default_queue_type].to_s)
      end
    end
  end
end
