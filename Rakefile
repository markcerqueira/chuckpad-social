require 'sinatra'
require 'sinatra/activerecord/rake'

require './controllers/application_controller'

require './config/environments' # database configuration

require 'config_env/rake_tasks'

ConfigEnv.init("#{__dir__}/config/env.rb")
