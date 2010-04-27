# Install hook code here
require 'fileutils'

def install(file)
  puts "Installing: #{file}"
  target = File.join(File.dirname(__FILE__), '..', '..', '..', file)
  if File.exists?(target)
    puts "target #{target} already exists, skipping"
  else
    FileUtils.cp File.join(File.dirname(__FILE__), file), target
  end
end

install File.join( 'script', 'yarb_server' )
install File.join( 'config', 'yarb.yml' )

puts IO.read(File.join(File.dirname(__FILE__), 'README'))

