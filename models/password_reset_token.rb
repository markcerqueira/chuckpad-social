class PasswordResetToken < ActiveRecord::Base

  TOKEN_EXPIRATION_TIME_MINUTES = 15

  # Generates a new password reset token and returns it to caller
  def self.generate_token(user)
    password_reset_token = PasswordResetToken.new do |t|
      t.user_id = user.id
      t.reset_token = SecureRandom.urlsafe_base64(32)
      t.expire_time = DateTime.now + TOKEN_EXPIRATION_TIME_MINUTES.minutes
    end

    password_reset_token.save

    return password_reset_token
  end

end
