class User < ActiveRecord::Base
  has_many :patches, foreign_key: :creator_id

  # Find a user by id, username, or email. If multiple params are passed
  # they will search in order declared (e.g. search by id first, username
  # second, email third, confirm_token fourth).
  def self.get_user(id: -1, username: nil, email: nil, confirm_token: nil)
    (User.find_by_id(id) if id != -1) ||
    (User.find_by_username(username) if username.present?) ||
    (User.find_by_email(email) if email.present?) ||
    (User.find_by_confirm_token(confirm_token) if confirm_token.present?)
  end

  # Finds user by username or email (using logic in get_user function) and
  # then verifies that the provided password is correct. If the user is not
  # found or the password is incorrect, nil is returned.
  def self.get_user_with_verification(username, email, password)
    user = get_user(username: username, email: email)

    if !user.nil? && user.password_hash == BCrypt::Engine.hash_secret(password, user.salt)
      return user
    end

    return nil
  end

  def display_str
    "#{username} (#{id})"
  end

  def get_patch_count
    all_patches = patches

    all_count     = all_patches.count
    visible_count = all_patches.visible.count
    hidden_count  = all_count - visible_count

    "#{all_count}/#{visible_count}/#{hidden_count}"
  end

end
