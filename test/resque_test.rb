require 'test_helper'

describe Resque::Job do
  before do
    @fake_queue = 'fake_queue'
    @worker = Resque::Worker.new(@fake_queue)
    # Resque checks redis for the worker's value and 
    # returns a hash decoded by MultiJSON
    @job =  {
      'queue'   => @fake_queue,
      'payload' => {
        'class' => 'SomeJob',
        'args'  => []
      } 
    }
  end

  describe '#job_from_same_queue_is_currently_being_run?' do
    it 'returns false if no workers' do
      Resque::Worker.expects(:working).returns([])
      Resque::Job
        .job_from_same_queue_is_currently_being_run?('some_queue')
        .must_equal(false)
    end

    it 'returns true if the queue name of any processing ' +
       'job matches the queue name passed in' do

      Resque::Worker.expects(:working).returns([@worker])
      @worker.expects(:job).returns(@job)
      Resque::Job
        .job_from_same_queue_is_currently_being_run?(@fake_queue)
        .must_equal(true)
    end

    it 'returns false if there are jobs but none from the specified queue' do
      Resque::Worker.expects(:working).returns([@worker])
      @worker.expects(:job).returns(@job)
      Resque::Job
        .job_from_same_queue_is_currently_being_run?('a_different_queue')
        .must_equal(false)
    end
  end

  describe '#reserve' do
    describe 'when there are no non-serial queues specified' do
      before do
        Resque::Plugins::RealSerialQueues.config = {}
      end

      it 'should return nil if job from requested queue is being performed' do
        Resque::Job
          .expects(:job_from_same_queue_is_currently_being_run?)
          .returns(true)
        Resque::Job.reserve('queue_name').must_equal(nil)
      end

      it 'should return at instance of Resque::Job if no ' +
         'job from requested queue is being performed' do
        Resque::Job
          .expects(:job_from_same_queue_is_currently_being_run?)
          .returns(false)

        Resque.expects(:pop).returns(@job)

        result = Resque::Job.reserve(@fake_queue)
        
        result.must_be_instance_of(Resque::Job)
      end
    end

    describe 'when there are non-serial queues specified' do
      before do
        @serial_queue = 'so_serial'
        @non_serial   = 'not_so_serial'
        Resque::Plugins::RealSerialQueues.config = {
          non_serial_queues: [@non_serial]
        }

        Resque.stubs(:pop).returns(@job)
      end
      
      describe 'and there is a job from the same queue being performed' do
        before do
          Resque::Job.stubs(:job_from_same_queue_is_currently_being_run?)
            .returns(true)
        end

        it 'should return an Resque::Job instance if in the non-serial queue' do
          result = Resque::Job.reserve(@non_serial)
          result.must_be_instance_of(Resque::Job)
        end

        it 'should return nil if not in the non-serial queue' do
          result = Resque::Job.reserve(@serial_queue)
          result.must_be_nil
        end
      end

      describe 'and there is no job from the same queue being performed' do
        before do
          Resque::Job.stubs(:job_from_same_queue_is_currently_being_run?)
            .returns(false)
        end

        it 'should return a Resque::Job instance if in non-serial queue' do
          result = Resque::Job.reserve(@non_serial)
          result.must_be_instance_of(Resque::Job)
        end

        it 'should return a Resque::Job instance if in serial queue' do
          result = Resque::Job.reserve(@serial_queue)
          result.must_be_instance_of(Resque::Job)
        end
      end
    end
  end
end

describe Resque::Plugins::RealSerialQueues do
  describe '#config=' do
    it 'should take in the config hash in a way that is accessible' do
      Resque::Plugins::RealSerialQueues.config = {
        non_serial_queues:[:camera, :bear]
      }

      Resque::Plugins::RealSerialQueues
        .non_serial_queues
        .must_equal([:camera, :bear])
    end

    it 'should throw an error if the config is not a Hash' do
      -> {
        Resque::Plugins::RealSerialQueues.config = 'good morning bear'
      }.must_raise(
        Resque::Plugins::RealSerialQueues::InvalidConfigurationError
      )
    end

    it 'should throw an error if non serial queues not specified in an array' do
      -> { 
        Resque::Plugins::RealSerialQueues.config = {
          non_serial_queues: 'best_queue, better_queue'
        } 
      }.must_raise(Resque::Plugins::RealSerialQueues::InvalidConfigurationError)
    end
  end
end