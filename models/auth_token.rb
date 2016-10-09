class AuthToken < ActiveRecord::Base

  IMPLEMENTATION_VERSION_PREFIX = 'v1-'

  # Generates a new auth token and returns it to caller
  def self.generate_token(user)
    auth_token = AuthToken.new do |t|
      t.user_id = user.id
      t.auth_token = IMPLEMENTATION_VERSION_PREFIX + SecureRandom.urlsafe_base64(32)
      t.token_created = DateTime.now
      t.last_access = DateTime.now
    end

    auth_token.save

    return auth_token
  end

end
