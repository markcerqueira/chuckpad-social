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

  # Finds user by username or email (using logic in get_user function) and
  # then verifies that the provided password is correct. If the user is not
  # found or the password is incorrect, nil is returned.
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

  def self.get_patch_count(user)
    all_patches = Patch.where('creator_id = ' + user.id.to_s)
    all_count = all_patches.size

    visible_patches = all_patches.where('hidden IS NOT true OR hidden IS null')
    visible_count = visible_patches.size

    hidden_patches = all_patches.where('hidden IS true')
    hidden_count = hidden_patches.size

    return all_count.to_s + ' / ' + visible_count.to_s + ' / ' + hidden_count.to_s
  end

end
