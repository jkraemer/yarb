module Yarb
  class Config

    # default config
    DEFAULTS = {
      'cfg'       => "#{RAILS_ROOT}/config/yarb.yml",
      'pid_file'  => "#{RAILS_ROOT}/log/yarb_server.pid",
      'log_file'  => "#{RAILS_ROOT}/log/yarb_server.log",
      'log_level' => 'debug'
    }

    # load the configuration file and apply default settings
    def initialize(file = DEFAULTS['cfg'])
      @everything = YAML.load(ERB.new(IO.read(file)).result)
      raise "malformed yarb config" unless @everything.is_a?(Hash)
      @config = DEFAULTS.merge(@everything[RAILS_ENV] || {})
    rescue
      puts "error reading config file: #{$!}, using defaults"
      @config = DEFAULTS
    end

    # treat the keys of the config data as methods
    def method_missing (name, *args)
      @config.has_key?(name.to_s) ? @config[name.to_s] : super
    end

  end
end