require 'test_helper'

require 'active_record'
ActiveRecord::Base.establish_connection({
  :adapter => 'sqlite3',
  :dbfile => 'test.db'
})
require File.join(File.dirname(__FILE__), 'fixtures', 'schema.rb')
ActiveRecord::Base.logger = RAILS_DEFAULT_LOGGER = Logger.new(File.join(File.dirname(__FILE__), 'log', 'test.log'))

require 'yarb'
require 'yarb/worker'
require 'async_job'

class TestWorker < Yarb::Worker
  def run
    return job_data[:result]
  end

  def precheck
    return job_data[:precheck]
  end

  def retry_interval
    return job_data[:retry_interval]
  end
end

class AsyncJobTest < Test::Unit::TestCase
  
  def test_should_create_job
    job = AsyncJob.create_job TestWorker, :result => 'success'
    job.reload
    assert job.run_at
    assert AsyncJob.waiting.include?(job)
    assert_equal('TestWorker', job.worker)
    assert_equal('success', job.load_job_data[:result])
  end
  
  def test_should_run_job
    job = AsyncJob.create_job TestWorker, :result => 'success'
    job.run!
    job.reload
    assert_equal(AsyncJob::FINISHED, job.status)
    assert res = job.load_job_results
    assert_equal('success', res)
  end
  
  def test_should_reschedule_job_with_failed_precheck
    job = AsyncJob.create_job TestWorker, :result => 'success', :precheck => false
    job.run!
    job.reload
    assert_equal(AsyncJob::FAILED, job.status)
    assert e = job.load_job_results[:error]
  end
  
  def test_should_reschedule_job_with_failed_precheck_if_interval_given
    job = AsyncJob.create_job TestWorker, :result => 'success', :precheck => false, :retry_interval => 10.minutes
    job.run!
    job.reload
    assert_equal(AsyncJob::WAITING, job.status)
    assert job.load_job_results.empty?
  end
  
end