require './controllers/application_controller'
require './models/patch'

require 'json'

class PatchController < ApplicationController

  TEN_KB_IN_BYTES = 10000

  def log(method, o)
    puts 'PatchController ' + method
    if not o.nil?
      puts ' - ' + o.to_s
    end
  end

  def to_json(patch)
    {
        'id' => patch.id,
        'name' => patch.name,
        'featured' => patch.featured,
        'documentation' => patch.documentation,
        'filename' => patch.filename,
        'content_type' => patch.content_type,
        'resource' => '/patch/show/' + patch.id.to_s
    }.to_json
  end

  # Ghetto but I wasn't able to find a better way to do this!
  def to_json_list(patches)
    i = 1
    length = patches.length

    result = '['

    patches.each do |patch|
      result += to_json(patch)

      if (i += 1) <= length
        result += ','
      end
    end

    result += ']'
    return result
  end

  post '/create_patch/?' do
    log('/create_patch', params[:patch])

    @patch = Patch.new(params[:patch]) do |t|
      if params[:patch][:data]
        filename = params[:patch][:data][:tempfile];
        if File.size(filename) > TEN_KB_IN_BYTES
          status 500
          return
        end

        t.data = filename.read
        t.filename = params[:patch][:data][:filename]
        t.content_type = params[:patch][:data][:type]
      end
    end

    if @patch.name.empty?
      @patch.name = @patch.filename
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
    erb :index
  end

  # get '/json/:id/?' do
  #   @patch = Patch.find_by_id(params[:id])
  #   to_json(@patch)
  # end

  get '/json/all/?' do
    log('/json/all', nil)
    content_type 'text/json'
    to_json_list(Patch.all)
  end

  get '/json/featured/?' do
    log('/json/featured', nil)
    content_type 'text/json'
    to_json_list(Patch.where('featured = true'))
  end

  get '/json/documentation/?' do
    log('/json/documentation', nil)
    content_type 'text/json'
    to_json_list(Patch.where('documentation = true'))
  end

  get '/delete/?' do
    log('delete', nil)

    Patch.delete_all
    redirect '/patch'
  end

  get '/show/?' do
    log('show', nil)

    @patches = Patch.all
    erb :index
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