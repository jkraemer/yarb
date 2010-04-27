require 'yaml'

class AsyncJob < ActiveRecord::Base
  WAITING = 'waiting'
  RUNNING = 'running'
  FINISHED = 'finished'
  FAILED = 'failed'

  # scheduled jobs
  named_scope :waiting, lambda{ {:conditions => ["status=? AND run_at <= ?", WAITING, Time.now.utc ], :order => 'run_at ASC'} }
  
  # running jobs, longest running first
  named_scope :running,  :conditions => { :status => RUNNING }, :order => 'updated_at ASC'
  
  # finished jobs, most recently finished first
  named_scope :finished, :conditions => { :status => FINISHED }, :order => 'updated_at DESC'

  # failed jobs, most recently failed first
  named_scope :failed, :conditions => { :status => FAILED }, :order => 'updated_at DESC'
  
  before_create :init_new_job
  
  attr_accessible
  
  def load_job_data
    YAML.load job_data unless job_data.blank?
  end
  def load_job_results
    YAML.load job_results unless job_results.blank?
  end
  
  # schedules the job to run again in interval seconds
  def run_again_in(interval, info = nil)
    self.job_results = { :info => info } if info
    self.status = WAITING
    self.run_at = Time.now.utc + interval
    save!
  end
  
  def run!
    update_attribute :status, RUNNING
    worker = init_worker
    info = ''
    if false != worker.precheck
      results = worker.run
      if Hash === results && wait_interval = results[:run_again_in]
        self.run_again_in wait_interval, results[:info]
      else
        self.job_results = results.to_yaml
        self.status = FINISHED
        save!
      end
    elsif interval = worker.retry_interval
      logger.info "job\n#{self.inspect}\nprecheck failed, retrying in #{interval} seconds."
      run_again_in interval, "precheck failed (#{info.blank? ? 'reason unknown' : info})"
    else
      failed!('precheck failed')
    end
  rescue Exception
    error = "error while executing job\n#{self.inspect}\n#{$!}\nbacktrace:\n#{$!.backtrace.join "\n"}"
    logger.error error
    failed! error
  end
  
  def failed!(error)
    self.job_results = { :error => error }.to_yaml
    self.status = FAILED
    save!
  end
  
  def self.create_job(worker_class, job_data = {})
    job = new
    job.run_at = job_data[:run_at] # defaults to Time.now
    job.worker = (String === worker_class ? worker_class : worker_class.name)
    job.job_data = job_data.to_yaml
    job.save!
    job
  end
  
  def self.next
    waiting.find :first
  end
  
  protected
  
  def init_worker
    self.worker.constantize.new(self)
  end
  
  def init_new_job
    self.status = WAITING
    self.job_results = {}.to_yaml
    self.run_at ||= Time.now
  end
  
end