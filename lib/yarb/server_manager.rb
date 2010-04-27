require 'optparse'
require 'logger'

$async_server_options = {
  'environment' => nil,
  'debug'       => nil,
  'root'        => nil
}

OptionParser.new do |optparser|
  optparser.banner = "Usage: #{File.basename($0)} [options] {start|stop|run}"

  optparser.on('-h', '--help', "This message") do
    puts optparser
    exit
  end
  
  optparser.on('-R', '--root=PATH', 'Set RAILS_ROOT to the given string') do |r|
    $async_server_options['root'] = r
  end

  optparser.on('-e', '--environment=NAME', 'Set RAILS_ENV to the given string') do |e|
    $async_server_options['environment'] = e
  end

  optparser.on('--debug', 'Include full stack traces on exceptions') do
    $async_server_options['debug'] = true
  end

  $async_server_action = optparser.permute!(ARGV)
  (puts optparser; exit(1)) unless $async_server_action.size == 1

  $async_server_action = $async_server_action.first
  (puts optparser; exit(1)) unless %w(start stop run).include?($async_server_action)
end

begin
  ENV['RAILS_ENV'] = $async_server_options['environment']
  # determine RAILS_ROOT unless already set
  RAILS_ROOT = $async_server_options['root'] || File.join(File.dirname(__FILE__), *(['..']*5)) unless defined? RAILS_ROOT
  # check if environment.rb is present
  rails_env_file = File.join(RAILS_ROOT, 'config', 'environment')
  raise "Unable to find Rails environment.rb at \n#{rails_env_file}.rb\nPlease use the --root option of async_server to point it to your RAILS_ROOT." unless File.exists?(rails_env_file+'.rb')
  
  RAILS_DEFAULT_LOGGER = Logger.new("#{RAILS_ROOT}/log/async_server_default.log")
  # load it
  require rails_env_file

  Yarb::Server.new.send($async_server_action)
rescue Exception => e
  $stderr.puts(e.message)
  $stderr.puts(e.backtrace.join("\n")) if $async_server_options['debug']
  exit(1)
end
