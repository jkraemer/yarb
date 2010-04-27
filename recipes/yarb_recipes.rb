# Usage:
#
# This will hook yarb's start/stop tasks into the standard
# deploy:{start|restart|stop} tasks so the server will be restarted along with
# the rest of your application.
#
# in case the recipes aren't loaded by capistrano, add something like
# Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
# to your Capfile. This will let Capistrano load recipes from all plugins your
# app is using.
#
namespace :yarb do

  desc "Stop the yarb server"
  task :stop, :roles => :app do
    rails_env = fetch(:rails_env, 'production')
    run "cd #{current_path}; script/yarb_server -e #{rails_env} stop || true"
  end

  desc "Start the yarb server"
  task :start, :roles => :app do
    rails_env = fetch(:rails_env, 'production')
    run "cd #{current_path}; script/yarb_server -e #{rails_env} start"
  end

  desc "Restart the yarb server"
  task :restart, :roles => :app do
    top.yarb.stop
    sleep 1
    top.yarb.start
  end

end

after  "deploy:stop",    "yarb:stop"
before "deploy:start",   "yarb:start"

before "deploy:restart", "yarb:stop"
after  "deploy:restart", "yarb:start"

