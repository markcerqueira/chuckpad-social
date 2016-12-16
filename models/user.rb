class User < ActiveRecord::Base
  has_many :patches, foreign_key: :creator_id

  MIN_PASSWORD_ENTROPY = 10

  # Username length constraints (inclusive on both ends)
  MIN_USERNAME_LENGTH = 2
  MAX_USERNAME_LENGTH = 20

  # Find a user by id, username, or email. If multiple params are passed
  # they will search in order declared (e.g. search by id first, username
  # second, email third, confirm_token fourth).
  #
  # Throws: UserNotFoundError
  def self.get_user(id: -1, username: nil, email: nil, confirm_token: nil)
    user = (User.find_by_id(id) if id != -1) ||
        ((User.where('lower(username) = ?', username.downcase).first) if username.present?) || # username is case-insensitive
        ((User.where('lower(email) = ?', email.downcase).first) if email.present?) || # email is case insensitive
        (User.find_by_confirm_token(confirm_token) if confirm_token.present?)

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

  # Helper method that creates a user from the params given, saves it, and returns it.
  # Throws an error with a message if anything goes wrong during the creation process.
  #
  # Throws: UserCreateError
  def self.create_user(params)
    username = params[:username]
    email = params[:email]
    password = params[:password]

    begin
      existing_user = User.get_user(username: username, email: email)
    rescue UserNotFoundError
      # Do nothing. We want to NOT find a user in this case.
    end

    unless existing_user.nil?
      LogHelper.user_log('create_user', 'user already exists for username = ' + username + '; email = ' + email)
      if existing_user.email.casecmp(email) == 0 && existing_user.username.casecmp(username) == 0
        raise UserCreateError, 'A user with that email address and username already exists.'
      elsif existing_user.email.casecmp(email) == 0
        raise UserCreateError, 'A user with that email address already exists.'
      else
        raise UserCreateError, 'A user with that username already exists.'
      end
    end

    # No user found so we can validate inputs and create a user

    # Check for username, password, and email being present
    if username.blank? || password.blank? || email.blank?
      raise UserCreateError, 'Username, password, and email are all required.'
    end

    # Check that username has only valid characters and isn't too long
    unless User.username_is_valid(username)
      raise UserCreateError, "Username can only use alphanumeric, period, underscore, and hyphen characters and between #{User::MIN_USERNAME_LENGTH}-#{User::MAX_USERNAME_LENGTH} characters."
    end

    # Check password strength
    if User.is_password_weak('create_user', username, password)
      raise UserCreateError, 'The password is too weak.'
    end

    # Validate email address
    unless EmailValidator.valid?(email)
      raise UserCreateError, 'Please enter a valid email.'
    end

    user = User.new do |u|
      u.username = username
      u.email = email
      u.salt = BCrypt::Engine.generate_salt
      u.password_hash = BCrypt::Engine.hash_secret(password, u.salt)
      u.email_confirmed = false
      u.confirm_token = SecureRandom.urlsafe_base64.to_s
    end

    unless user.save
      LogHelper.user_log('create_user', 'Error saving created user')
      raise PatchCreateError
    end

    return user
  end

  VALID_USERNAME_REGEX = /^[a-zA-Z0-9_.-]{#{MIN_USERNAME_LENGTH},#{MAX_USERNAME_LENGTH}}$/

  # Returns true if username is alphanumeric (also including . _ -) and is of proper length
  def self.username_is_valid(username)
    return username.matches? VALID_USERNAME_REGEX
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
