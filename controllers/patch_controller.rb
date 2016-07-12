require './controllers/application_controller'

class PatchController < ApplicationController

  # File size limit for patch creation
  TEN_KB_IN_BYTES = 10000

  # Used by /patches/new
  RECENT_PATCHES_TO_RETURN = 20;

  # Helper logging method
  def log(method, o)
    shared_log('PatchController', method, o)
  end

  # Redirects to '/patch' with message
  def redirect_to_index_with_status_msg(msg)
    redirect_with_status_message(msg, '/patch')
  end

  # Returns true if the passed user has permissions to modify the patch
  def user_can_modify_patch(caller, request, current_user, patch, fail_quietly = false)
    if current_user.admin
      return true
    end

    if current_user.id == patch.creator_id
      return true;
    end

    unless fail_quietly
      if from_native_client(request)
        fail_with_json_msg(500, 'User does not have permission to modify patch with id ' + patch.id.to_s)
      else
        redirect_to_index_with_status_msg('User does not have permission to modify patch with id ' + patch.id.to_s)
      end
    end

    return false
  end

  # Gets patch with passed patch_id
  def get_patch(caller, request, patch_id, fail_quietly = false)
    patch = Patch.find_by_id(patch_id)
    if patch.nil?
      log(caller, 'No patch found')

      unless fail_quietly
        if from_native_client(request)
          fail_with_json_msg(500, 'Unable to find patch with id ' + params[:id].to_s)
        else
          redirect_to_index_with_status_msg('Unable to find patch with id ' + params[:id].to_s)
        end
      end

      return nil, true
    end

    return patch, false
  end

  # Gets user supporting both web and iOS-based queries
  def get_user(caller, request, params, fail_quietly = false)
    if from_native_client(request)
      # Native clients: this will return nil if we cannot find the user OR the password is incorrect
      current_user = User.get_user_with_verification(params[:username], params[:email], params[:password])
    else
      # Web clients: we know they are authenticated if session[:user_id] exists
      current_user = User.get_user(session[:user_id], nil, nil)
    end

    if current_user.nil?
      log(caller, 'No valid user found and fail_quietly = ' + fail_quietly.to_s)
      unless fail_quietly
        if from_native_client(request)
          fail_with_json_msg(500, 'This call requires a logged in user')
        else
          redirect_to_index_with_status_msg('This call requires a logged in user')
        end
      end

      # nil = no (validated) user found, true = found an error
      return nil, true
    end

    return current_user, false
  end

  # Returns a patch and false if an authenticated user is found and has permission to modify a patch
  # Nil (no patch) and true (error) are returned in every other case
  def get_user_authenticated_and_modifiable_patch(caller, request, params, fail_quietly = false)
    patch, error = get_patch(caller, request, params[:id], fail_quietly)
    if error
      log(caller, 'get_patch call had an error')
      return nil, true
    end

    current_user, error = get_user(caller, request, params, fail_quietly)
    if error
      log(caller, 'get_user call had an error')
      return nil, true
    end

    unless user_can_modify_patch(caller, request, current_user, patch, fail_quietly)
      log(caller, 'user_can_modify_patch call had an error')
      return nil, true
    end

    return patch, false
  end

  # Index page that shows index.erb and lists all patches
  get '/' do
    log('/', nil)
    @latest_status_message = session[:status]
    @patches = Patch.order('id DESC').all
    @logged_in_user = User.get_user(session[:user_id], nil, nil)
    erb :index
  end

  # Creates a new patch
  post '/create_patch/?' do
    log('/create_patch', params)

    # User must be logged in to create a patch
    current_user, error = get_user('/create_patch', request, params)
    if error
      log('/create_patch', 'get_user call had an error')
      return
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
      p.revision = 1
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

  # Updates an existing patch. Supports updating file and name of the patch. Revision is
  # incremented when an update occurs.
  post '/update/?' do
    log('update', nil)

    params[:id] = params[:patch][:id]

    patch, error = get_user_authenticated_and_modifiable_patch('/update', request, params)
    if error
      log('/toggle_hidden', 'get_user_authenticated_and_modifiable_patch call had an error')
      return
    end

    data = params[:patch][:data]
    unless data.nil?
      patch.data = params[:patch][:data][:tempfile].read
      patch.filename = params[:patch][:data][:filename]
      patch.content_type = params[:patch][:data][:type]
      revision_made = true
    end

    name = params[:patch][:name]
    unless name.nil? or name.empty?
      patch.name = name
      revision_made = true
    end

    if revision_made
      patch.revision = patch.revision + 1
      patch.save
    end

    # TODO Switch on if a change was made?
    redirect_to_index_with_status_msg('Updated patch with id ' + params[:id].to_s)
  end

  # Returns information for patch with parameter id in JSON format
  get '/json/info/:id/?' do
    patch, error = get_patch('/json/info', request, params[:id])
    if error
      log('/json/info', 'get_patch call had an error')
      return
    end

    patch.to_json
  end

  # Returns patches for the logged in user in JSON format
  get '/my/?' do
    current_user, error = get_user('/my', request, params, false)
    if error
      log('/my', 'get_user call had an error')
      return
    end

    Patch.where(creator_id: current_user.id).to_json
  end

  # Returns patches for the given user in JSON format
  # If the id requested belongs to the user making the request, hidden patches will be returned;
  # otherwise only non-hidden patches will be returned
  get '/json/user/:id/?' do
    log('/json/user', nil)
    content_type 'text/json'

    show_hidden = false
    current_user, error = get_user('/json/user', request, params, true)
    unless current_user.nil?
      show_hidden = current_user.id.to_i == params[:id].to_i
    end

    patches = Patch.where(creator_id: params[:id])

    unless show_hidden
      patches.visible
    end

    patches.order('id DESC').to_json
  end

  # Returns recently created patches
  get '/new/?' do
    log('/new', nil)
    content_type 'text/json'
    Patch.visible.order('id DESC').limit(RECENT_PATCHES_TO_RETURN).to_json
  end

  # Returns all (non-hidden) patches as a JSON list
  get '/json/all/?' do
    log('/json/all', nil)
    content_type 'text/json'
    Patch.visible.to_json
  end

  # Returns all (non-hidden) featured patches as a JSON list
  get '/json/featured/?' do
    log('/json/featured', nil)
    content_type 'text/json'
    Patch.visible_featured.to_json
  end

  # Returns all (non-hidden) documentation patches as a JSON list
  get '/json/documentation/?' do
    log('/json/documentation', nil)
    content_type 'text/json'
    Patch.visible_documentation.to_json
  end

  # Downloads patch file for given patch id
  get '/download/:id/?' do
    patch, error = get_patch('/download', request, params[:id])
    if error
      log('/download', 'get_patch call had an error')
      return
    end

    # Downloads the patch data
    attachment patch.filename
    content_type 'application/octet-stream'
    patch.data
  end

  # Deletes patch for given patch id
  get '/delete/:id/?' do
    log('/delete', nil)

    patch, error = get_user_authenticated_and_modifiable_patch('/delete', request, params)
    if error
      log('/delete', 'get_user_authenticated_and_modifiable_patch call had an error')
      return
    end

    patch.delete

    redirect_to_index_with_status_msg('Deleted patch with id ' + params[:id].to_s)
  end

  # Toggles hidden visibility on patch
  get '/toggle_hidden/:id/?' do
    log('toggle_hidden', nil)

    patch, error = get_user_authenticated_and_modifiable_patch('/toggle_hidden', request, params)
    if error
      log('/toggle_hidden', 'get_user_authenticated_and_modifiable_patch call had an error')
      return
    end

    patch.hidden = !patch.hidden

    patch.save

    redirect_to_index_with_status_msg('Toggled hidden state for patch with id ' + params[:id].to_s)
  end

end