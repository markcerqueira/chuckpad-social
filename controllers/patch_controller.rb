require './controllers/application_controller'
require './models/patch'

class PatchController < ApplicationController

  def log(method, o)
    puts 'PatchController ' + method
    if not o.nil?
      puts ' - ' + (o)
    end
  end

  post '/create_patch/?' do
    log('/create_patch', params[:patch])

    @patch = Patch.new(params[:patch]) do |t|
      if params[:patch][:data]
        t.data = params[:patch][:data][:tempfile].read
        t.filename = params[:patch][:data][:filename]
        t.content_type = params[:patch][:data][:type]
      end
    end

    @patch.featured = params[:patch].has_key?('featured')
    @patch.documentation = params[:patch].has_key?('documentation')

    # save
    if @patch.save
      redirect '/patch'
    else
      'Sorry, there was an error!'
    end
  end

  get '/' do
    log('/', nil)

    @patches = Patch.all
    erb :patches
  end

  get '/delete/?' do
    log('delete', nil)

    Patch.delete_all
    redirect '/patch'
  end

  get '/show/?' do
    log('show', nil)

    @patches = Patch.all
    erb :patches
  end

  get '/download/:id/?' do
    log('download', nil)

    @patch = Patch.find_by_id(params[:id])

    if @patch.nil?
      log('download', 'No patch found')
      status 404
      return
    end

    attachment @patch.filename
    content_type 'application/octet-stream'
    @patch.data
  end

  get '/delete/:id/?' do
    log('delete', nil)

    @patch = Patch.find_by_id(params[:id])

    if @patch.nil?
      log('delete', 'No patch found')
      status 404
      return
    end

    @patch.delete

    redirect '/patch'
  end

end