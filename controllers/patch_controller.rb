require './controllers/application_controller'

class PatchController < ApplicationController

  # Used by /patches/new
  RECENT_PATCHES_TO_RETURN = 20

  # Returns true if the passed user has permissions to modify the patch
  def user_can_modify_patch(caller, request, current_user, patch, fail_quietly = false)
    if current_user.admin
      return true
    end

    if current_user.id == patch.creator_id
      return true;
    end

    unless fail_quietly
      ResponseHelper.error(self, request, 'User does not have permission to modify patch with guid ' + patch.guid.to_s)
    end

    return false
  end

  # Gets patch with passed patch_id
  def get_patch(caller, request, guid, fail_quietly = false)
    patch = Patch.find_by_guid(guid)
    if patch.nil?
      LogHelper.patch_controller_log(caller, 'No patch found')
      unless fail_quietly
        ResponseHelper.error(self, request, 'Unable to find patch with guid ' + params[:guid].to_s)
      end

      return nil, true
    end

    return patch, false
  end

  # Gets user supporting both web and iOS-based queries
  def get_user_from_params(caller, request, params, fail_quietly = false)
    begin
      if from_native_client(request)
        # Native clients: this will throw a UserNotFoundError/AuthTokenInvalidError if we can't find user or auth token is invalid
        current_user = User.get_user_with_verification(params[:username], params[:email], params[:auth_token])
      else
        # Web clients: we know they are authenticated if session[:user_id] exists
        current_user = User.get_user(id: session[:user_id])
      end
      return current_user, false
    rescue UserNotFoundError
      LogHelper.patch_controller_log(caller, 'No valid user found and fail_quietly = ' + fail_quietly.to_s)
      unless fail_quietly
        ResponseHelper.error(self, request, 'This call requires a logged in user')
      end
    rescue AuthTokenInvalidError
      LogHelper.patch_controller_log(caller, 'Invalid auth token found and fail_quietly = ' + fail_quietly.to_s)
      unless fail_quietly
        ResponseHelper.auth_error(self, request, 'Your auth token is invalid. Please log in again.')
      end
    end

    # nil = no (validated) user found, true = found an error
    return nil, true
  end

  # Returns a patch and false if an authenticated user is found and has permission to modify a patch
  # Nil (no patch) and true (error) are returned in every other case
  def get_user_authenticated_and_modifiable_patch(caller, request, params, fail_quietly = false)
    patch, error = get_patch(caller, request, params[:guid], fail_quietly)
    if error
      LogHelper.patch_controller_log(caller, 'get_patch call had an error')
      return nil, true
    end

    current_user, error = get_user_from_params(caller, request, params, fail_quietly)
    if error
      LogHelper.patch_controller_log(caller, 'get_user call had an error')
      return nil, true
    end

    unless user_can_modify_patch(caller, request, current_user, patch, fail_quietly)
      LogHelper.patch_controller_log(caller, 'user_can_modify_patch call had an error')
      return nil, true
    end

    return patch, false
  end

  # Index page that shows index.erb and lists all patches
  get '/' do
    LogHelper.patch_controller_log('', nil)
    @latest_status_message = session[:status]
    @patches = Patch.order('id DESC').all

    begin
      @logged_in_user = User.get_user(id: session[:user_id])
    rescue UserNotFoundError
      # Do nothing
    end

    erb :index
  end

  # Creates a new patch
  post '/create/?' do
    # LogHelper.patch_controller_log('create', params)

    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    # User must be logged in to create a patch
    current_user, error = get_user_from_params('create', request, params)
    if error
      LogHelper.patch_controller_log('create', 'get_user call had an error')
      return
    end

    begin
      patch = Patch.create_patch(current_user, params)
      ResponseHelper.success(self, request, patch.to_json, 'Patch created with id = ' + patch.id.to_s)
    rescue PatchCreateError => error
      ResponseHelper.error(self, request, error.message)
    end
  end

  # Updates an existing patch. Supports updating data file, name of the patch, and visibility. Revision is
  # incremented when an update occurs.
  post '/update/?' do
    # LogHelper.patch_controller_log('update', params)

    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    patch, error = get_user_authenticated_and_modifiable_patch('update', request, params)
    if patch.nil? or error.present?
      LogHelper.patch_controller_log('update', 'get_user_authenticated_and_modifiable_patch call had an error')
      ResponseHelper.error(self, request, 'There was an error finding the patch to update. Please try again.')
      return
    end

    begin
      patch.update_patch(params)
      ResponseHelper.success(self, request, patch.to_json, 'Updated patch with id ' + params[:id].to_s)
    rescue PatchUpdateError => error
      ResponseHelper.error(self, request, error.message)
    end
  end

  # Returns information for patch with parameter guid in JSON format
  get '/info/:guid/?' do
    patch, error = get_patch('json/info', request, params[:guid])
    if error
      LogHelper.patch_controller_log('json/info', 'get_patch call had an error')
      return
    end

    ResponseHelper.success_with_json_msg(self, patch.to_json)
  end

  # Returns patches for the logged in user in JSON format
  get '/my/?' do
    current_user, error = get_user_from_params('my', request, params, false)
    if error
      LogHelper.patch_controller_log('my', 'get_user call had an error')
      return
    end

    ResponseHelper.success_with_json_msg(self, Patch.where(creator_id: current_user.id, patch_type: params[:type].to_i).to_json)
  end

  # Returns patches for the given user in JSON format
  # If the id requested belongs to the user making the request, hidden patches will be returned;
  # otherwise only non-hidden patches will be returned
  get '/user/:id/?' do
    show_hidden = false
    current_user, error = get_user_from_params('user', request, params, true)
    unless current_user.nil?
      show_hidden = current_user.id.to_i == params[:id].to_i
    end

    patches = Patch.where(creator_id: params[:id])

    unless show_hidden
      patches.visible
    end

    ResponseHelper.success_with_json_msg(self, patches.order('id DESC').to_json)
  end

  # Returns recently created patches
  get '/new/?' do
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false).order('id DESC').limit(RECENT_PATCHES_TO_RETURN).to_json)
  end

  # Returns all (non-hidden) featured patches as a JSON list
  get '/featured/?' do
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, featured: true).to_json)
  end

  # Returns all (non-hidden) documentation patches as a JSON list
  get '/documentation/?' do
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, documentation: true).to_json)
  end

  # Downloads patch file for given patch id
  get '/download/:guid/?' do
    patch, error = get_patch('download', request, params[:guid])
    if error
      LogHelper.patch_controller_log('download', 'get_patch call had an error')
      return
    end

    patch.download_count += 1
    patch.save

    # Downloads the patch data
    attachment patch.name
    content_type 'application/octet-stream'
    patch.data
  end

  # Returns data for extra meta-data resource
  get '/download/extra/:guid/?' do
    patch, error = get_patch('download/extra', request, params[:guid])
    if error
      LogHelper.patch_controller_log('download/extra', 'get_patch call had an error')
      return
    end

    attachment patch.name
    content_type 'application/octet-stream'
    patch.extra_data
  end

  # Deletes patch for given patch id
  get '/delete/:guid/?' do
    # LogHelper.patch_controller_log('delete', nil)

    patch, error = get_user_authenticated_and_modifiable_patch('delete', request, params)
    if error
      LogHelper.patch_controller_log('delete', 'get_user_authenticated_and_modifiable_patch call had an error')
      return
    end

    patch.delete

    ResponseHelper.success(self, request, 'Successfully deleted patch')
  end

  # Toggle report abuse for a patch
  post '/report/:guid/?' do
    # LogHelper.patch_controller_log('report', params)

    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    # User must be logged in to report an abusive patch
    current_user, error = get_user_from_params('report', request, params)
    if error
      LogHelper.patch_controller_log('report', 'get_user call had an error')
      return
    end

    patch = Patch.find_by_guid(params[:guid])

    # This can happen if a user is reporting a patch that was deleted
    if patch.nil?
      ResponseHelper.success(self, request, 'Patch has already been deleted by creator')
      return
    end

    # See if a AbuseReport record already exists
    abuse_report = AbuseReport.where(patch_id: patch.id, user_id: current_user.id).first
    
    if abuse_report.nil? && params[:is_abuse] == "1"
      LogHelper.patch_controller_log('report', "reporting patch with id #{patch.id}")
      abuse_report = AbuseReport.new do |r|
        r.user_id = current_user.id
        r.patch_id = patch.id
      end

      patch.abuse_count = patch.abuse_count + 1

      abuse_report.save
      patch.save

      return_string = 'Patch abuse report received'
    elsif abuse_report.present? && params[:is_abuse] != "1"
      LogHelper.patch_controller_log('report', "rescinding report for patch with id #{patch.id}")
      abuse_report.delete

      patch.abuse_count = patch.abuse_count - 1
      patch.save

      return_string = 'Patch abuse report undone'
    else
      # Client and server state are somehow inconsistent
      LogHelper.patch_controller_log('report', 'No valid branches to handle report abuse')
      return_string = 'Patch report received'
    end

    ResponseHelper.success(self, request, return_string)
  end

end