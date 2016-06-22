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
        # TODO This can be removed at some point since hidden things should not be seen externally
        'hidden' => patch.hidden,
        'filename' => patch.filename,
        'content_type' => patch.content_type,
        'creator_id' => patch.creator_id,
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

  def redirect_to_index_with_status_msg(msg)
    session[:status] = msg
    redirect '/patch'
  end

  # Index page that shows index.erb and lists all patches
  get '/' do
    log('/', nil)
    @latest_status_message = session[:status]
    @patches = Patch.find(:all, :order  => 'id DESC')
    @logged_in_user = User.get_user(session[:user_id], nil, nil)
    erb :index
  end

  # Creates a new patch
  post '/create_patch/?' do
    log('/create_patch', params)

    # User must be logged in to create a patch
    current_user = nil;
    if from_native_client(request)
      # Native clients: this will return nil if we cannot find the user OR the password is incorrect
      current_user = User.get_user_with_verification(params[:username], params[:email], params[:password])
    else
      # Web clients: we know they are authenticated if session[:user_id] exists
      current_user = User.get_user(session[:user_id], nil, nil)
    end

    if current_user.nil?
      log('/create_patch', 'No valid user found')
      if from_native_client(request)
        fail_with_json_msg(500, 'You must be logged in to create a patch')
        return
      else
        redirect_to_index_with_status_msg('Error! You must be logged in to create a patch')
      end
    end

    # Make sure file is below file size limit
    if File.size(params[:patch][:data][:tempfile]) > TEN_KB_IN_BYTES
      log('/create_patch', 'File size too large')
      if from_native_client(request)
        fail_with_json_msg(500, 'File size is too large')
        return
      else
        redirect_to_index_with_status_msg('Error! File size is too large!')
      end
    end

    # Create patch
    patch = Patch.new do |p|
      p.name = params[:patch][:name]
      p.featured = params[:patch].has_key?('featured')
      p.documentation = params[:patch].has_key?('documentation')
      p.hidden = params[:patch].has_key?('hidden')
      p.data = params[:patch][:data][:tempfile].read
      p.filename = params[:patch][:data][:filename]
      p.content_type = params[:patch][:data][:type]
      p.creator_id = current_user.id
      if p.name.nil? or p.name.empty?
        p.name = p.filename
      end
    end

    # Save patch
    if patch.save
      if from_native_client(request)
        success_with_json_msg(to_hash(patch))
      else
        redirect_to_index_with_status_msg('Patch created with id = ' + patch.id.to_s)
      end
    else
      if from_native_client(request)
        fail_with_json_msg(500, 'Error saving patch file')
        return
      else
        redirect_to_index_with_status_msg('There was an error saving the patch')
      end
    end
  end

  # Returns information for patch with parameter id in JSON format
  get '/json/info/:id/?' do
    patch = Patch.find_by_id(params[:id])

    if patch.nil?
      if from_native_client(request)
        fail_with_json_msg(500, 'Unable to find patch with id ' + params[:id].to_s)
        return
      else
        redirect_to_index_with_status_msg('Unable to find patch with id ' + params[:id].to_s)
      end
    end

    to_json(patch)
  end

  # Returns all patches as a JSON list
  get '/json/all/?' do
    log('/json/all', nil)
    content_type 'text/json'
    # TODO Once we finalize schema for 1.0 we can remove IS null
    to_json_list(Patch.where('hidden IS NOT true OR hidden IS null'))
  end

  # Returns all featured patches as a JSON list
  get '/json/featured/?' do
    log('/json/featured', nil)
    content_type 'text/json'
    # TODO Once we finalize schema for 1.0 we can remove IS null
    to_json_list(Patch.where('featured = true').where('hidden != false OR hidden IS null'))
  end

  # Returns all documentation patches as a JSON list
  get '/json/documentation/?' do
    log('/json/documentation', nil)
    content_type 'text/json'
    # TODO Once we finalize schema for 1.0 we can remove IS null
    to_json_list(Patch.where('documentation = true').where('hidden != false OR hidden IS null'))
  end

  # Deletes all patches
  get '/wipe/?' do
    log('wipe', nil)
    patchCount = Patch.count
    Patch.delete_all
    redirect_to_index_with_status_msg(patchCount.to_s + ' patches wiped')
  end

  # Downloads patch file for given patch id
  get '/download/:id/?' do
    log('download', nil)

    patch = Patch.find_by_id(params[:id])

    if patch.nil?
      if from_native_client(request)
        fail_with_json_msg(500, 'Unable to find patch with id ' + params[:id].to_s)
        return
      else
        redirect_to_index_with_status_msg('Unable to find patch with id ' + params[:id].to_s)
      end
    end

    # Downloads the patch data
    attachment patch.filename
    content_type 'application/octet-stream'
    patch.data
  end

  # Deletes patch for given patch id
  get '/delete/:id/?' do
    log('delete', nil)

    patch = Patch.find_by_id(params[:id])

    if patch.nil?
      log('delete', 'No patch found')
      if from_native_client(request)
        fail_with_json_msg(500, 'Unable to find patch with id ' + params[:id].to_s)
        return
      else
        redirect_to_index_with_status_msg('Unable to find patch with id ' + params[:id].to_s)
      end
    end

    patch.delete

    redirect_to_index_with_status_msg('Deleted patch with id ' + params[:id].to_s)
  end

  get '/toggle_hidden/:id/?' do
    log('toggle_hidden', nil)

    patch = Patch.find_by_id(params[:id])

    # We do this elsewhere so refactor it out somewhere?
    if patch.nil?
      log('toggle_hidden', 'No patch found')
      if from_native_client(request)
        fail_with_json_msg(500, 'Unable to find patch with id ' + params[:id].to_s)
        return
      else
        redirect_to_index_with_status_msg('Unable to find patch with id ' + params[:id].to_s)
      end
    end

    if patch.hidden
      patch.hidden = false
    else
      patch.hidden = true
    end

    patch.save

    redirect_to_index_with_status_msg('Toggled hidden state for patch with id ' + params[:id].to_s)
  end

end