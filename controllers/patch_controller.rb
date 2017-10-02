require './controllers/application_controller'

class PatchController < ApplicationController

  # Used by /patches/new
  RECENT_PATCHES_TO_RETURN = 20

  # Patches per world region
  PATCHES_PER_WORLD_REGION = 10

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
    ResponseHelper.success_with_json_msg(self, Patch.where(creator_id: current_user.id, patch_type: params[:type].to_i, deleted: false).to_json)
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

    patches = Patch.where(creator_id: params[:id], deleted: false)

    unless show_hidden
      patches.visible
    end

    AnalyticsHelper.track_patch_event(action: 'user', params: params)
    ResponseHelper.success_with_json_msg(self, patches.order('id DESC').to_json)
  end

  # Returns recently created patches
  get '/new/?' do
    AnalyticsHelper.track_patch_event(action: 'new', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, deleted: false).order('id DESC').limit(RECENT_PATCHES_TO_RETURN).to_json)
  end

  # Returns all (non-hidden) featured patches as a JSON list
  get '/featured/?' do
    AnalyticsHelper.track_patch_event(action: 'featured', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, featured: true, deleted: false).to_json)
  end

  # Returns all (non-hidden) documentation patches as a JSON list
  get '/documentation/?' do
    AnalyticsHelper.track_patch_event(action: 'documentation', params: params)
    ResponseHelper.success_with_json_msg(self, Patch.where(patch_type: params[:type].to_i, hidden: false, documentation: true, deleted: false).to_json)
  end

  # Downloads patch file for given patch id
  get '/download/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
      patch_resource = PatchResource.get_most_recent_resource(params[:guid])
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

    patch_resource.data
  end

  # Returns a random collection of patches from around the world
  get '/world/?' do
    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    AnalyticsHelper.track_patch_event(action: 'world', params: params)

    world_patches ||= []

    # Grab PATCHES_PER_WORLD_REGION from each of the latitude regions in ranges
    # This logic can be updated to support longitudes or larger/finer ranges of coordinates
    ranges ||= [[-180, -120], [-120, -60], [-60, 0], [0, 60], [60, 120], [120, 180]]
    ranges.each { |range|
      # mySQL uses RAND(), PostgreSQL uses RANDOM()
      world_patches.concat Patch.where('lat >= ? AND lat <= ? AND patch_type = ? AND hidden = FALSE', range[0], range[1], params[:type].to_i).order('RANDOM()').first(PATCHES_PER_WORLD_REGION)
    }

    ResponseHelper.success_with_json_msg(self, world_patches.to_json)
  end

  # URL for ChucK rendering service. The first points to the Digital Ocean droplet, the second to a local Docker container
  # See more: https://github.com/markcerqueira/chuck-renderer
  CHUCK_RENDERER_URL = 'http://chuck-renderer.4860ca31.svc.dockerapp.io:9000/render/'
  # CHUCK_RENDERER_URL = '0.0.0.0:9000/render/'

  # Takes ChucK file, renders it as an m4a, and returns the resource
  get '/play/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
      patch_resource = PatchResource.get_most_recent_resource(params[:guid])
    rescue PatchNotFoundError
      ResponseHelper.resource_error(self)
      return
    end

    # TODO Enforce only patches with type ChucK can get past this point

    # Data is binary array so write that to a temporary file. Use a consistent filename so we only do this operation
    # once per patch guid + revision
    renderer_file_name = 'renderer/' + patch.guid + patch.revision.to_s + '.ck'
    if !File.exist?(renderer_file_name)
      File.open(renderer_file_name, 'wb') {
          |f| f.write(patch_resource.data)
      }
    end

    # Hit our chuck-renderer endpoint to generate a .m4a file to play
    # See more: https://github.com/markcerqueira/chuck-renderer
    RestClient.post CHUCK_RENDERER_URL, :resource => File.open(renderer_file_name, 'r')
  end

  get '/versions/?' do
    begin
      patch = Patch.get_patch(params[:guid])
      patch_resources = PatchResource.get_resources(params[:guid])
    rescue PatchNotFoundError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    ResponseHelper.success_with_json_msg(self, patch_resources)
  end

  get '/versions/download/:guid/:version/?' do
    begin
      patch = Patch.get_patch(params[:guid])

      # We will only get one item in this query, but we need to use first here so we get a PatchResource instead of a
      # PatchResourceRelation!
      patch_resource = PatchResource.where(patch_guid: params[:guid], version: params[:version].to_i).first
      if patch_resource.nil?
        raise PatchNotFoundError
      end
    rescue
      ResponseHelper.resource_error(self)
      return
    end

    attachment params[:guid]
    content_type 'application/octet-stream'

    patch_resource.data
  end

  # Returns data for extra meta-data resource
  get '/download/extra/:guid/?' do
    begin
      patch = Patch.get_patch(params[:guid])
    rescue PatchNotFoundError
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

    patch.deleted = true
    patch.save

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