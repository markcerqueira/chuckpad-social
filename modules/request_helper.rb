module RequestHelper

  CHUCKPAD_SOCIAL_IOS = 'chuckpad-social-ios'

  # Returns true if the request is being made from a "native" (e.g. iOS) client
  def self.from_native_client(request)
    return request.user_agent.include? CHUCKPAD_SOCIAL_IOS
  end

end
