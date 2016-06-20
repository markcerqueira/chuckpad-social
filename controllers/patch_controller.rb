require './controllers/application_controller'

class PatchController < ApplicationController

  TEN_KB_IN_BYTES = 10000

  # Helper logging method
  def log(method, o)
    shared_log('PatchController', method, o)
  end

  # Returns passed patch object as a hash
  def to_hash(patch)
    {
        'id' => patch.id,
        'name' => patch.name,
        'featured' => patch.featured,
        'documentation' => patch.documentation,
        'filename' => patch.filename,
        'content_type' => patch.content_type,
        'resource' => '/patch/show/' + patch.id.to_s
    }
  end

  # Converts passed patch as a JSON object
  def to_json(patch)
    to_hash(patch).to_json
  end

  # Converts passed list patches as a JSON list
  def to_json_list(patches)
    return patches.each_with_object([]) { |patch, array| array << to_hash(patch) }.to_json
  end

  # Index page that shows index.erb and lists all patches
  get '/' do
    log('/', nil)
    # @patches = Patch.all
    @patches = Patch.find(:all, :order  => 'id DESC')
    erb :index
  end

  # Creates a new patch
  post '/create_patch/?' do
    log('/create_patch', params)

    from_web = params[:web].to_s == "1"

    params.delete :web
    
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

    if @patch.name.nil? or @patch.name.empty?
      @patch.name = @patch.filename
    end

    @patch.featured = params[:patch].has_key?('featured')
    @patch.documentation = params[:patch].has_key?('documentation')

    # save
    if @patch.save
      # Do not call redirect when we are called from non-web sources (maybe make separate API?)
      if from_web
        log('/create_patch', 'redirecting')
        redirect '/patch'
      else
        status 200
        return to_hash(@patch).to_json
      end
    else
      if from_web
        'Sorry, there was an error!'
      else
        status 500
        body 'Error!'
      end
    end
  end

  # Returns information for patch with parameter id in JSON format
  get '/json/info/:id/?' do
    @patch = Patch.find_by_id(params[:id])
    to_json(@patch)
  end

  # Returns all patches as a JSON list
  get '/json/all/?' do
    log('/json/all', nil)
    content_type 'text/json'
    to_json_list(Patch.all)
  end

  # Returns all featured patches as a JSON list
  get '/json/featured/?' do
    log('/json/featured', nil)
    content_type 'text/json'
    to_json_list(Patch.where('featured = true'))
  end

  # Returns all documentation patches as a JSON list
  get '/json/documentation/?' do
    log('/json/documentation', nil)
    content_type 'text/json'
    to_json_list(Patch.where('documentation = true'))
  end

  # Deletes all patches
  get '/wipe/?' do
    log('wipe', nil)

    Patch.delete_all
    redirect '/patch'
  end

  # Downloads patch file for given patch id
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

  # Deletes patch for given patch id
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