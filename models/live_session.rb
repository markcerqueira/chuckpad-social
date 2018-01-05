class LiveSession < ActiveRecord::Base

  STATE_ACTIVE = 0
  STATE_CLOSED = 1

  # Helper method that creates a live session from the params given, saves it, and returns it.
  # Throws an error with a message if anything goes wrong during the creation process.
  #
  # Throws: LiveSessionCreateError
  def self.create_live_session(user, params)
    live_session = LiveSession.new do |ls|
      ls.session_guid = SecureRandom.hex(12)
      ls.title = (params[:session_title] || '')
      ls.creator_id = user.id
      ls.session_type = params[:session_type].to_i
      ls.created_at = Time.now
      ls.last_active = Time.now
    end

    unless live_session.save
      LogHelper.live_session_log('create_live_session', 'Error saving the newly created live session')
      raise LiveSessionCreateError
    end

    return live_session
  end

  # Returns the live session with the given guid. Throws an error with a message if no live session is found.
  #
  # Throws: LiveSessionNotFoundError
  def self.get_live_session(session_guid)
    live_session = LiveSession.find_by_session_guid(session_guid)
    if live_session.nil?
      raise LiveSessionNotFoundError
    end
    return live_session
  end

  # Finds the user and the live session specified in the params and ensures that the live session specified can be modified
  # by the user specified. Throws an error if any of the aforementioned operations fail.
  #
  # Throws: UserNotFoundError, AuthTokenInvalidError, LiveSessionPermissionError
  def self.get_modifiable_live_session(request, params)
    current_user = User.get_user_from_params(request, params)
    live_session = LiveSession.get_live_session(params[:session_guid])

    if current_user.id != live_session.creator_id
      raise LiveSessionPermissionError
    end

    return live_session
  end

  # Converts live_session to json using to_hash method
  def as_json(options)
    to_hash()
  end

  # Returns live_session object as a hash
  def to_hash()
    {
        'session_guid' => session_guid,
        'creator_id' => creator_id,
        'state' => state,
        'title' => title,
        'occupancy' => occupancy,
        'created_at' => created_at.strftime('%Y-%m-%d %H:%M:%S'), # http://stackoverflow.com/a/9132422/265791
        'last_active' => last_active.strftime('%Y-%m-%d %H:%M:%S')
    }.tap do |h|
      creator = User.get_user(id: creator_id)
      h['creator_username'] = creator.username
    end
  end

end
