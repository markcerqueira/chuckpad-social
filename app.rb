require 'sinatra'
require 'active_record'

require './config/environments' # database configuration
require './models/model'        # Model class
require './models/patch'        # Patch class

get '/' do
	erb :index
end

post '/submit' do
	@model = Model.new(params[:model])
	if @model.save
		redirect '/models'
	else
		"Sorry, there was an error!"
	end
end


post '/create_patch' do
  print '/create_patch - params = ' + params[:patch]

	@patch = Patch.new(params[:patch]) do |t|
		if params[:patch][:data]
			t.data = params[:patch][:data][:tempfile].read
			# t.filename  = params[:patch][:data].original_filename
			# t.mime_type = params[:patch][:data].content_type

		end
	end

	# normal save
	if @patch.save
		redirect '/patches'
	else
		render :action => "new"
	end
end

get '/models' do
	@models = Model.all
	erb :models
end

get '/patches' do
	@patches = Patch.all
	erb :patches
end

after do
  # Close the connection after the request is done so that we don't
  # deplete the ActiveRecord connection pool.
  ActiveRecord::Base.connection.close
end
