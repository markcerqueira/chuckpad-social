class User < ActiveRecord::Base
  has_many :patches, foreign_key: :creator_id

  # Find a user by id, username, or email. If multiple params are passed
  # they will search in order declared (e.g. search by id first, username
  # second, email third).
  def self.get_user(id, username, email)
    unless id.nil?
      user = User.find_by_id(id)
      if !user.nil?
        return user
      end
    end

    unless username.nil?
      user = User.find_by_username(username)
      if !user.nil?
        return user
      end
    end

    unless email.nil?
      user = User.find_by_email(email)
      if !user.nil?
        return user
      end
    end

    return nil
  end

  def self.get_user_with_verification(username, email, password)
    user = get_user(nil, username, email)
    if user.password_hash == BCrypt::Engine.hash_secret(password, user.salt)
      return user
    end

    return nil
  end

  def display_str
    username + ' (' + id.to_s + ')'
  end

end
