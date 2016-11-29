# require './app'
# run Sinatra::Application

$stdout.sync = true

# Load config/env.rb first so application_controller can initialize properly
require 'config_env'
ConfigEnv.init("#{__dir__}/config/env.rb")

require './controllers/application_controller'

Dir.glob('./{config,models,modules,errors,helpers,controllers}/*.rb').each { |file| require file }

map('/') { run ApplicationController }
map('/patch') { run PatchController }
map('/user/') { run UserController }
