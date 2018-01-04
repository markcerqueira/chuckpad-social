# require './app'
# run Sinatra::Application

$stdout.sync = true

# Load config/env.rb first so application_controller can initialize properly
require 'config_env'
ConfigEnv.init("#{__dir__}/config/env.rb")

require './controllers/application_controller'

Dir.glob('./{config,controllers,errors,extensions,helpers,models,modules}/*.rb').each { |file| require file }

map('/') { run WebController }
map('/patch') { run PatchController }
map('/user/') { run UserController }
map('/live/') { run LiveController }
map('/.well-known/') { run ChallengeController }