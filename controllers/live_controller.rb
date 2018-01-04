require './controllers/application_controller'

class LiveController < ApplicationController

  post '/create/?' do

  end

  get '/users/?' do
    erb :live
  end

end
