class AuthTokenInvalidError < StandardError

  def initialize(msg='Your auth token is invalid. Please log in again.')
    super
  end

end
