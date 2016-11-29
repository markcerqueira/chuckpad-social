class User < ActiveRecord::Base
  has_many :patches, foreign_key: :creator_id

  MIN_PASSWORD_ENTROPY = 6

  # Username length constraints (inclusive on both ends)
  MIN_USERNAME_LENGTH = 2
  MAX_USERNAME_LENGTH = 20

  # Find a user by id, username, or email. If multiple params are passed
  # they will search in order declared (e.g. search by id first, username
  # second, email third, confirm_token fourth).
  #
  # Throws: UserNotFoundError
  def self.get_user(id: -1, username: nil, email: nil, confirm_token: nil)
    user = (User.find_by_id(id) if id != -1) || (User.find_by_username(username) if username.present?) ||
           (User.find_by_email(email) if email.present?) || (User.find_by_confirm_token(confirm_token) if confirm_token.present?)

    if user.nil?
      raise UserNotFoundError
    else
      return user
    end
  end

  # Finds user by username or email (using logic in get_user function) and
  # then verifies that the provided auth_token is valid. If the user is not
  # found or the auth_token is not found, nil is returned.
  #
  # Throws: UserNotFoundError, AuthTokenInvalidError
  def self.get_user_with_verification(username, email, auth_token)
    # This can throw a UserNotFoundError
    user = get_user(username: username, email: email)

    authToken = AuthToken.find_by_auth_token(auth_token)
    if !authToken.nil? && user.id == authToken.user_id
      authToken.last_access = DateTime.now
      authToken.save
      return user
    end

    # If user is found but auth token is not, we may have invalidated it so throw an AuthTokenInvalidError
    raise AuthTokenInvalidError
  end

  # Returns true if username is alphanumeric and is of proper length
  def self.username_is_valid(username)
    username.count("^a-zA-Z0-9_\.\-").zero? && username.length.between?(MIN_USERNAME_LENGTH, MAX_USERNAME_LENGTH)
  end

  # Simple password checker to make sure password is not equal to username and not weak
  def self.is_password_weak(caller, username, password)
    if password.nil? || password.length == 0
      LogHelper.user_log(caller, 'password is empty')
      return true
    end

    if !username.nil? && (password.eql? username)
      LogHelper.user_log(caller, 'password is the same as username')
      return true
    end

    password_entropy = StrongPassword::StrengthChecker.new(password).calculate_entropy

    LogHelper.user_log(caller, 'password.length = ' + password.length.to_s + '; password_entropy = '+  password_entropy.to_s)

    return password_entropy.to_i < MIN_PASSWORD_ENTROPY
  end

  # Converts user to json using to_hash method
  def as_json(options = nil, auth_token = nil)
    to_hash(auth_token)
  end

  # Returns user object as a hash
  def to_hash(auth_token)
    {
        'id' => id,
        'username' => username,
        'email' => email
    }.tap do |h|
      # Only add the auth token if we passed it in
      h['auth_token'] = auth_token unless auth_token.blank?
    end
  end

  # Used on the web page
  def get_patch_count
    all_patches = patches

    all_count     = all_patches.count
    visible_count = all_patches.visible.count
    hidden_count  = all_count - visible_count

    "#{all_count}/#{visible_count}/#{hidden_count}"
  end

end
