require './controllers/application_controller'

class UserController < ApplicationController

  # Scenario: someone tries to log in at time 0. And then tries again at time 1. We will sleep for 1 second to make
  # sure login requests are at least 2 seconds part.
  LOGIN_THROTTLE_SECONDS = 2

  # Index page that loads user.erb
  get '/' do
    @users = User.order('id DESC').all

    begin
      @logged_in_user = User.get_user(id: session[:user_id])
    rescue UserNotFoundError
      # Nothing to do
    end

    @latest_status_message = session[:status]
    erb :user
  end

  # Renders landing page for changing password
  get '/password/confirm/?' do
    password_reset_token = PasswordResetToken.find_by_reset_token(params[:token])

    # Token in params is not valid, user ids do not match, or token has expired. Abort!
    if password_reset_token.nil? || password_reset_token.user_id.to_s != params[:id].to_s || password_reset_token.expire_time < DateTime.now
      @invalid_token = true
    end

    unless @invalid_token
      puts params
      @user_id = params[:id]
      @token = params[:token]
    end

    erb :password
  end

  # Finishes the change password flow
  post '/password/finalize/?' do
    puts params

    # TODO Why are hidden field variables getting a trailing `/` attached to them?
    password_reset_token = PasswordResetToken.find_by_reset_token(params[:token].chomp('/'))

    # Token in params is not valid, user ids do not match, or token has expired. Abort!
    if password_reset_token.nil? || password_reset_token.user_id.to_s != params[:user_id].chomp('/').to_s || password_reset_token.expire_time < DateTime.now
      @invalid_after_finalize = true
    end

    unless @invalid_after_finalize
      user = User.get_user(id: params[:user_id].chomp('/'))
      new_password = params[:new_password]
      new_password.strip!

      # TODO Weak password validation
      user.salt = BCrypt::Engine.generate_salt
      user.password_hash = BCrypt::Engine.hash_secret(new_password, user.salt)

      user.save
      password_reset_token.delete

      @change_password_complete = true
    end

    erb :password
  end

  # Request a password reset
  post '/password/reset/?' do
    username_or_email = params[:username_or_email]
    username_or_email.strip

    begin
      user = User.get_user(username: username_or_email, email: username_or_email)
    rescue UserNotFoundError
      LogHelper.user_controller_log('/password/reset', 'No user found')
      ResponseHelper.error(self, request, 'No user was found with that username or email. Please try again.')
      return
    end

    password_reset_token = PasswordResetToken.generate_token(user)

    if request.nil?
      base_url = 'https://chuckpad-social.herokuapp.com'
    else
      base_url = request.base_url
    end

    subject = 'Reset your ChuckPad password'
    html_body = erb :'emails/password_reset_email', locals: {
        username: user.username,
        reset_link: base_url.to_s + 'user/password/confirm/?token=' + password_reset_token.reset_token + '&id=' + password_reset_token.user_id.to_s,
        expire_time: PasswordResetToken::TOKEN_EXPIRATION_TIME_MINUTES.to_s
    }

    MailHelper.send_email(user.email, subject, html_body)

    ResponseHelper.success(self, request, 'Password reset sent via email.')
  end

  def is_user_logged_in
    return session.has_key?('user_id')
  end

  def get_logged_in_user
    return @logged_in_user
  end

  # Sends confirmation email to user passed in
  # Confirmation email is HTML-based and is pulled from the views/welcome_email.erb file
  def send_confirmation_email(user, request)
    if user.nil?
      LogHelper.user_controller_log('send_confirmation_email', 'user is nil')
      return
    end

    if request.nil?
      base_url = 'https://chuckpad-social.herokuapp.com'
    else
      base_url = request.base_url
    end

    subject = 'Welcome to ChuckPad!'
    html_body = erb :'emails/welcome_email', locals: {
        username: user.username,
        confirm_link: base_url.to_s + '/user/confirm/' + user.confirm_token
    }

    MailHelper.send_email(user.email, subject, html_body)

    LogHelper.user_controller_log('send_confirmation_email', 'Confirmation email sent to ' + user.email)
  end

  # Sends confirmation email for the currently logged in user. Will NOT send an email if the user has already confirmed
  # their email.
  get '/confirm_email/?' do
    begin
      if from_native_client(request)
        logged_in_user = User.get_user(username: params[:username_or_email], email: params[:username_or_email])
      else
        logged_in_user = User.get_user(id: session[:user_id])
      end
    rescue UserNotFoundError
      LogHelper.user_controller_log('confirm_email', 'No logged in user found')
      redirect_to_index_with_status_msg('Unable to send confirmation email until a user logs in')
    end

    if logged_in_user.email_confirmed
      LogHelper.user_controller_log('confirm_email', 'User has already confirmed email')
      redirect_to_index_with_status_msg('User has already confirmed email so not sending another email')
    end

    send_confirmation_email(logged_in_user, request)
    redirect_to_index_with_status_msg('Confirmation email sent to ' + logged_in_user.email)
  end

  # Creates a new user
  post '/create_user/?' do
    username = params[:user][:username]
    username.strip

    email = params[:user][:email]
    email.strip

    password = params[:password]
    password.strip

    admin = params[:user].has_key?('admin')


    begin
      existing_user = User.get_user(username: username, email: email)
    rescue UserNotFoundError
      # Do nothing. We want to NOT find a user.
    end

    unless existing_user.nil?
      LogHelper.user_controller_log('create_user', 'user already exists for username = ' + username + '; email = ' + email)

      if existing_user.email.casecmp(email) == 0 && existing_user.username.casecmp(username) == 0
        message = 'A user with that email address and username already exists.'
      elsif existing_user.email.casecmp(email) == 0
        message = 'A user with that email address already exists.'
      else
        message = 'A user with that username already exists.'
      end

      ResponseHelper.error(self, request, message)
      return
    end

    # No user found so we can validate inputs and create a user

    # Check for username, password, and email being present
    if username.blank? || password.blank? || email.blank?
      LogHelper.user_controller_log('create_user', 'one or more params are empty')
      ResponseHelper.error(self, request, 'Username, password, and email are all required')
      return
    end

    # Check that username has only valid characters and isn't too long
    unless User.username_is_valid(username)
      LogHelper.user_controller_log('create_user', 'invalid characters in username ' + username)
      ResponseHelper.error(self, request, "Username can only use alphanumeric, period, underscore, and hyphen characters and between #{User::MIN_USERNAME_LENGTH}-#{User::MAX_USERNAME_LENGTH} characters")
      return
    end

    # Check password strength
    if User.is_password_weak('create_user', username, password)
      LogHelper.user_controller_log('create_user', 'password is weak')
      ResponseHelper.error(self, request, 'The password is too weak')
      return
    end

    # Validate email address
    unless EmailValidator.valid?(email)
      LogHelper.user_controller_log('create_user', 'email is valid')
      ResponseHelper.error(self, request, 'Please enter a valid email')
      return
    end

    user = User.new do |u|
      u.username = username
      u.email = email
      u.admin = admin
      u.salt = BCrypt::Engine.generate_salt
      u.password_hash = BCrypt::Engine.hash_secret(password, u.salt)
      u.email_confirmed = false
      u.confirm_token = SecureRandom.urlsafe_base64.to_s
    end

    user.save

    auth_token = AuthToken.generate_token(user)

    send_confirmation_email(user, request)

    ResponseHelper.success(self, request, user.as_json(nil, auth_token.auth_token), 'User created with id ' + user.id.to_s)
  end

  # Given token passed in url, finds the associated user and flags their email as confirmed
  # NOTE: This is a web-only API and should not be called from native clients
  get '/confirm/:token/?' do
    token = params[:token].to_s

    if token.nil? || token.empty?
      LogHelper.user_controller_log('confirm/:token/', 'token is nil or empty')
      return
    end

    begin
      user = User.get_user(confirm_token: token)
    rescue UserNotFoundError
      LogHelper.user_controller_log('confirm/:token/', 'Could not find user for confirm token')
      redirect_to_index_with_status_msg('Unable to find a user with confirm token = ' + token)
    end

    user.email_confirmed = true
    user.save

    redirect_to_index_with_status_msg('Email confirmed for user ' + user.username)
  end

  post '/change_password/?' do
    begin
      if from_native_client(request)
        logged_in_user = User.get_user_with_verification(params[:username], params[:email], params[:auth_token])
      else
        logged_in_user = User.get_user(id: session[:user_id])
      end
    rescue UserNotFoundError
      LogHelper.user_controller_log('change_password', 'No user found')
      ResponseHelper.error(self, request, 'Could not find user', 'Unable to change password as no user is currently logged in')
      return
    rescue AuthTokenInvalidError
      LogHelper.user_controller_log(caller, 'Invalid auth token found and fail_quietly = ' + fail_quietly.to_s)
      ResponseHelper.auth_error(self, request, 'Your auth token is invalid. Please log in again.')
      return
    end

    new_password = params[:new_password]
    new_password.strip!

    if User.is_password_weak('change_password', nil, new_password)
      LogHelper.user_controller_log('change_password', 'password is weak')
      ResponseHelper.error(self, request, 'Please enter a valid email')
      return
    end

    logged_in_user.salt = BCrypt::Engine.generate_salt
    logged_in_user.password_hash = BCrypt::Engine.hash_secret(new_password, logged_in_user.salt)

    logged_in_user.save

    ResponseHelper.success(self, request, 'Password updated')
  end

  # Clears session cookie (web) or invalidates auth token (native clients)
  post '/logout/?' do
    LogHelper.user_controller_log('logout', params)

    # Logging out on web
    unless from_native_client(request)
      user_id = session[:user_id]
      session[:user_id] = nil
      redirect_to_index_with_status_msg('Logged out user with id ' + user_id.to_s)
    end

    # Logging out on native clients
    token_invalidated = AuthToken.invalidate_token(params[:username], params[:email], params[:auth_token])

    if token_invalidated
      ResponseHelper.success(self, request, 'Successfully logged out')
    else
      ResponseHelper.error(self, request, 'Unable to log user out')
    end
  end

  # Logs in as a user
  post '/login/?' do
    username_or_email = params[:username_or_email]
    username_or_email.strip

    password = params[:password]
    password.strip

    # Check for username, password, and email being present
    if username_or_email.blank? || password.blank?
      LogHelper.user_controller_log('login', 'one or more params are empty')
      ResponseHelper.error(self, request, 'Username/email and password are required.')
      return
    end

    begin
      user = User.get_user(username: username_or_email, email: username_or_email)
    rescue UserNotFoundError
      LogHelper.user_controller_log('login', 'Login failed; no user found')
      ResponseHelper.error(self, request, 'Unable to find user with details ' + params[:username_or_email])
      return
    end

    # If someone is trying to log in too rapidly, slow them down a bit
    unless user.last_login_attempt.nil?
      seconds_since_last_login = (DateTime.now.to_f - user.last_login_attempt.to_f).to_f
      if seconds_since_last_login < LOGIN_THROTTLE_SECONDS
        sleep_length = LOGIN_THROTTLE_SECONDS - seconds_since_last_login
        LogHelper.user_controller_log('login', "User attempted to login too quickly so sleeping for #{sleep_length} seconds")
        sleep(sleep_length)
      end
    end

    user.last_login_attempt = DateTime.now
    user.save

    if user.password_hash == BCrypt::Engine.hash_secret(password, user.salt)
      session[:user_id] = user.id
      # No current notion of session for native clients
    else
      LogHelper.user_controller_log('login', 'Bad password')
      ResponseHelper.error(self, request, 'Login failed because of bad password')
      return
    end

    if from_native_client(request)
      auth_token = AuthToken.generate_token(user)
      auth_token_value = (user.as_json(nil, auth_token.auth_token))
    end
    ResponseHelper.success(self, request, if auth_token_value.nil? then '' else auth_token_value end, 'Logged in successfully')
  end

end
