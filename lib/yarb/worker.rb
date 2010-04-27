module Yarb
  
  # Worker base class
  #
  # The job configuration hash can be accessed via the job_data accessor method. A logger is also available.
  class Worker
    
    attr_accessor :logger, :job, :job_data
    
    def initialize(job)
      @job = job
      @job_data = job.load_job_data
      @logger = job.logger rescue nil
      @logger ||= RAILS_DEFAULT_LOGGER
      create
    end
    
    # This hook is called upon creation of the worker, override to customize initialization of the worker.
    # Each job gets it's own job instance, so feel free to initialize instance variables for later use.
    def create
    end

    # override to check if the worker really should be executed (return false in order to halt execution of the job)
    # the default implementation just returns true.
    def precheck
      true
    end
    
    # override to have jobs with failed the precheck to be re-executed automatically after x seconds
    # by default returns nil to indicate that jobs whose precheck failed shouldn't be re-scheduled.
    def retry_interval
      nil
    end
    
    # Called when the job is run. Override with your job code.
    def run
      raise "Implement #run in your worker subclass!"
    end
    
  end
end
