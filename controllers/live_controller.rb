require './controllers/application_controller'

class LiveController < ApplicationController

  # Creates a new live session
  post '/create/?' do
    # LogHelper.live_controller_log('create', params)

    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    # User must be logged in to create a live session
    begin
      current_user = User.get_user_from_params(request, params)
    rescue StandardError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    end

    # Create the live session
    begin
      live_session = LiveSession.create_live_session(current_user, params)
      AnalyticsHelper.track_live_event(action: 'create', params: params)
      ResponseHelper.success(self, request, live_session.to_json, 'Live session created with guid = ' + live_session.session_guid)
    rescue LiveSessionCreateError => error
      ResponseHelper.error(self, request, error.message)
    end
  end

  # Closes an existing live session
  post '/close/?' do
    # LogHelper.live_controller_log('close', params)

    begin
      DigestHelper.validate_digest(request.params)
    rescue DigestError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    # Get a "modifiable" live session (this requires an authenticated user that created the live session)
    begin
      live_session = LiveSession.get_modifiable_live_session(request, params)
    rescue UserNotFoundError, AuthTokenInvalidError => error
      ResponseHelper.get_user_error(self, request, error)
      return
    rescue LiveSessionPermissionError => error
      ResponseHelper.error(self, request, error.message)
      return
    end

    live_session.state = LiveSession::STATE_CLOSED
    live_session.save

    AnalyticsHelper.track_live_event(action: 'close', params: params)
    ResponseHelper.success(self, request, live_session.to_json, 'Updated live session with guid ' + params[:session_guid])
  end

end
