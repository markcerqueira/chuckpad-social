require 'sinatra'
require 'sinatra/activerecord/rake'

require './controllers/application_controller'

require './config/environments' # database configuration

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'tests/*_test.rb'
end
