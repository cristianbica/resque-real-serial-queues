require 'test_helper'

describe Resque::Job do
  before do
    @fake_queue = 'fake_queue'
    @worker = Resque::Worker.new(@fake_queue)
    @job =  { # Resque checks redis for the worker's value and returns a hash decoded by MultiJSON
      'queue'   => @fake_queue,
      'payload' => {
        'class' => 'SomeJob',
        'args'  => []
      } 
    }
  end

  describe '#job_from_same_queue_is_currently_being_run' do
    it 'returns false if no workers' do
      Resque::Worker.expects(:working).returns([])
      Resque::Job
        .job_from_same_queue_is_currently_being_run('some_queue').must_equal(false)
    end

    it 'returns true if the queue name of any processing job matches the queue name passed in' do
      Resque::Worker.expects(:working).returns([@worker])
      @worker.expects(:job).returns(@job)
      Resque::Job
        .job_from_same_queue_is_currently_being_run(@fake_queue).must_equal(true)
    end

    it 'returns false if there are jobs but none from the specified queue' do
      Resque::Worker.expects(:working).returns([@worker])
      @worker.expects(:job).returns(@job)
      Resque::Job
        .job_from_same_queue_is_currently_being_run('an_entirely_different_queue').must_equal(false)
    end
  end

  describe '#reserve' do
    it 'should return nil if a job from the requested queue is being performed' do
      Resque::Job.expects(:job_from_same_queue_is_currently_being_run).returns(true)
      Resque::Job.reserve('queue_name').must_equal(nil)
    end

    it 'should return at instance of Resque::Job if no job from requested queue is being performed' do
      Resque::Job.expects(:job_from_same_queue_is_currently_being_run).returns(false)
      Resque.expects(:pop).returns(@job)
      result = Resque::Job.reserve(@fake_queue)
      
      result.must_be_instance_of(Resque::Job)
    end
  end
end