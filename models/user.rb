class User < ActiveRecord::Base

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

end