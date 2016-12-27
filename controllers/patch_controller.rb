require './controllers/application_controller'

class PatchController < ApplicationController

  # Used by /patches/new
  RECENT_PATCHES_TO_RETURN = 20

  # Index page that shows index.erb and lists all patches
  get '/' do
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
    begin
      current_user = User.get_user_from_params(request, params)
    rescue StandardError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    end

    # Create the patch
    begin
      patch = Patch.create_patch(current_user, params)
      AnalyticsHelper.track_patch_event(action: 'create', params: params)
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

    # Get a "modifiable" patch (this requires an authenticated user that owns the patch)
    begin
      patch = Patch.get_modifiable_patch(request, params)
    rescue UserNotFoundError, AuthTokenInvalidError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    rescue PatchNotFoundError, PatchPermissionError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    begin
      patch.update_patch(params)
      AnalyticsHelper.track_patch_event(action: 'update', params: params)
      ResponseHelper.success(self, request, patch.to_json, 'Updated patch with id ' + params[:id].to_s)
    rescue PatchUpdateError => error
      ResponseHelper.error(self, request, error.message)
    end
  end

  # Returns information for patch with parameter guid in JSON format
  get '/info/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
    rescue PatchNotFoundError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    AnalyticsHelper.track_patch_event(action: 'info', params: params)
    ResponseHelper.success_with_json_msg(self, patch.to_json)
  end

  # Returns patches for the logged in user in JSON format
  get '/my/?' do
    # To get my patches, there must be a user logged in
    begin
      current_user = User.get_user_from_params(request, params)
    rescue StandardError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    end

    AnalyticsHelper.track_patch_event(action: 'my', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(creator_id: current_user.id, patch_type: params[:type].to_i).to_json)
  end

  # Returns patches for the given user in JSON format. If the id requested belongs to the user making the request,
  # hidden patches will be returned; otherwise only non-hidden patches will be returned.
  get '/user/:id/?' do
    begin
      user = User.get_user(id: params[:id].to_i)
    rescue UserNotFoundError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    show_hidden = false
    begin
      user = User.get_user_from_params(request, params)
      show_hidden = user.id.to_i == params[:id].to_i
    rescue StandardError => error
      # Ignore. If we don't find a user we will only show visible patches.
    end

    patches = Patch.where(creator_id: params[:id])

    unless show_hidden
      patches.visible
    end

    AnalyticsHelper.track_patch_event(action: 'user', params: params)
    ResponseHelper.success_with_json_msg(self, patches.order('id DESC').to_json)
  end

  # Returns recently created patches
  get '/new/?' do
    AnalyticsHelper.track_patch_event(action: 'new', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false).order('id DESC').limit(RECENT_PATCHES_TO_RETURN).to_json)
  end

  # Returns all (non-hidden) featured patches as a JSON list
  get '/featured/?' do
    AnalyticsHelper.track_patch_event(action: 'featured', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, featured: true).to_json)
  end

  # Returns all (non-hidden) documentation patches as a JSON list
  get '/documentation/?' do
    AnalyticsHelper.track_patch_event(action: 'documentation', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, documentation: true).to_json)
  end

  # Downloads patch file for given patch id
  get '/download/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
    rescue PatchNotFoundError
      ResponseHelper.resource_error(self)
      return
    end

    patch.download_count += 1
    patch.save

    params[:type] = patch.patch_type
    AnalyticsHelper.track_patch_event(action: 'download', params: params)

    attachment patch.name
    content_type 'application/octet-stream'
    patch.data
  end

  # Returns data for extra meta-data resource
  get '/download/extra/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
    rescue PatchNotFoundError => error
      ResponseHelper.resource_error(self)
      return
    end

    params[:type] = patch.patch_type
    AnalyticsHelper.track_patch_event(action: 'download/extra', params: params)

    attachment patch.name
    content_type 'application/octet-stream'
    patch.extra_data
  end

  # Deletes patch for given patch id
  get '/delete/:guid/?' do
    # LogHelper.patch_controller_log('delete', nil)

    # Get a "modifiable" patch (this requires an authenticated user that owns the patch)
    begin
      patch = Patch.get_modifiable_patch(request, params)
    rescue UserNotFoundError, AuthTokenInvalidError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    rescue PatchNotFoundError, PatchPermissionError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    patch.delete

    AnalyticsHelper.track_patch_event(action: 'delete', params: params)
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
    begin
      current_user = User.get_user_from_params(request, params)
    rescue StandardError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    end

    # Ensure the patch still exists
    begin
      patch = Patch.get_patch(params[:guid])
    rescue PatchNotFoundError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    result_string = AbuseReport.create_or_delete(patch, current_user.id, params[:is_abuse] == "1")

    AnalyticsHelper.track_patch_event(action: 'report', params: params)
    ResponseHelper.success(self, request, result_string)
  end

end