require 'thread'
require 'yaml'
require 'erb'

module Yarb

  # This class acts as a server regularly checking the job queue and processing jobs
  # as they come in.
  #
  # Usage: 
  # - modify RAILS_ROOT/config/yarb.yml to suit your needs. 
  # - run script/yarb_server to start the server:
  # script/yarb_server -e production start
  # - to stop the server run
  # script/yarb_server -e production stop
  #
  class Server
    include UnixDaemon

    cattr_accessor :running
    attr_reader :logger
    
    def initialize
      
      ActiveRecord::Base.verification_timeout = 14400
      ActiveRecord::Base.establish_connection
      
      # ActiveRecord::Base.allow_concurrency = true
      # require 'ar_mysql_auto_reconnect_patch'
      
      @cfg = Yarb::Config.new
      ActiveRecord::Base.logger = @logger = Logger.new(@cfg.log_file)
      ActiveRecord::Base.logger.level = Logger.const_get(@cfg.log_level.upcase) rescue Logger::DEBUG
      # if @cfg.script
      #   path = File.join(RAILS_ROOT, @cfg.script) 
      #   load path
      #   @logger.info "loaded custom startup script from #{path}"
      # end
    end

    # start the server as a daemon process
    def start
      platform_daemon do
        trap("TERM") do
          $stdout.puts "stopping yarb server..."
          Yarb::Server.running = false
        end
        run
      end
    end

    # run the server and block until it exits
    def run
      $stdout.puts("starting yarb server...")
      self.class.running = true
      while self.class.running
        ActiveRecord::Base.verify_active_connections!
        if (job = AsyncJob.next)
          job.run!
        else
          5.times { sleep 6 if self.class.running } # sleep, but dont delay shutdown too much
        end
      end
    rescue Exception => e
      logger.error e.to_s
      $stdout.puts e.to_s
      raise
    end
    
    protected

      # def reconnect_when_needed(clazz)
      #   retried = false
      #   begin
      #     yield
      #   rescue ActiveRecord::StatementInvalid => e
      #     if e.message =~ /MySQL server has gone away/
      #       if retried
      #         raise e
      #       else
      #         @logger.info "StatementInvalid caught, trying to reconnect..."
      #         clazz.connection.reconnect!
      #         retried = true
      #         retry
      #       end
      #     else
      #       @logger.error "StatementInvalid caught, but unsure what to do with it: #{e}"
      #       raise e
      #     end
      #   end
      # end

  end
end


