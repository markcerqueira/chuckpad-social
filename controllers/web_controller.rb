require './controllers/application_controller'

class WebController < ApplicationController

  # index.erb display in recent patches mode
  get '/?' do
    @mode = 'recent'
    @patches = Patch.where(patch_type: Patch::MINI_AUDICLE_TYPE, hidden: false, documentation: false, deleted: false).order('id DESC').limit(PatchController::RECENT_PATCHES_TO_RETURN)

    erb :index
  end

  # index.erb display in documentation mode
  get '/examples/?' do
    @mode = 'examples'
    @patches = Patch.where(patch_type: Patch::MINI_AUDICLE_TYPE, hidden: false, documentation: true, deleted: false).order('id DESC')

    erb :index
  end

  # index.erb display patches for a particular user
  post '/find/?' do
    redirect "/find/#{params[:username]}"
  end

  get '/find/:username/?' do
    @mode = 'user'
    @search_username = params[:username]

    begin
      user = User.get_user(username: @search_username)
      @patches = Patch.where(patch_type: Patch::MINI_AUDICLE_TYPE, hidden: false, creator_id: user.id, deleted: false).order('id DESC')
    rescue UserNotFoundError
      # TODO Show that we could not find the user
      @mode = 'recent'
      @patches = Patch.where(patch_type: Patch::MINI_AUDICLE_TYPE, hidden: false, deleted: false).order('id DESC').limit(PatchController::RECENT_PATCHES_TO_RETURN)

    end

    erb :index
  end

  # about.erb display
  get '/about/?' do
    erb :about
  end

  get '/renderer/?' do
    redirect 'http://chuck-renderer.4860ca31.svc.dockerapp.io:9000/debug'
  end

end

