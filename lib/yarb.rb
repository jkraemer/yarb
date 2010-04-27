# Yarb
module Yarb
  def self.create_job(worker_class, args = {})
    AsyncJob.create_job worker_class, args
  end
end

