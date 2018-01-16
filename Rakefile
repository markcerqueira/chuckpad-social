require 'sinatra'
require 'sinatra/activerecord/rake'

require './controllers/application_controller'
require './models/live_session'

require './config/environments' # database configuration

require 'config_env/rake_tasks'

ConfigEnv.init("#{__dir__}/config/env.rb")

# Closes LiveSessions that haven't been active in the last 10 minutes
# This task will run on Heroku via the Herok uScheduler: https://devcenter.heroku.com/articles/scheduler
task :close_stale_live_sessions do
  now = Time.now
  LiveSession.all.each do |ls|
    if ((now - ls.last_active) / 60) > 10
      ls.state = LiveSession::STATE_CLOSED
      ls.save
    end
  end
end
