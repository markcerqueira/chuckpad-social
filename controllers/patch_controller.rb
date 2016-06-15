require './controllers/application_controller'

class PatchController < ApplicationController

  post '/create_patch' do
    print '/create_patch'
    print params[:patch]

    @patch = Patch.new(params[:patch]) do |t|
      if params[:patch][:data]
        t.data = params[:patch][:data][:tempfile].read
        t.filename  = params[:patch][:data][:filename]
        t.content_type = params[:patch][:data][:type]
      end
    end

    # Not working right now
    if @patch.featured.nil?
      @patch.featured = true
    end
    if @patch.documentation.nil?
      @patch.documentation = true
    end

    # save
    if @patch.save
      redirect '/patch'
    else
      'Sorry, there was an error!'
    end
  end

  get '/' do
    @patches = Patch.all
    erb :patches
  end

  get '/delete' do
    Patch.delete_all
    redirect '/patch'
  end

  get '/show/:id' do
    @patch = Patch.find_by_id(params[:id])

    attachment @patch.filename
    content_type 'application/octet-stream'
    @patch.data
  end

end