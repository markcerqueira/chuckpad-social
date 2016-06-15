# require './app'
# run Sinatra::Application

require './controllers/application_controller'

Dir.glob('./{config,models,helpers,controllers}/*.rb').each { |file| require file }

map('/patch') { run PatchController }
map('/') { run ApplicationController }
