require './controllers/application_controller'

class UserController < ApplicationController

  # Scenario: someone tries to log in at time 0. And then tries again at time 1. We will sleep for 1 second to make
  # sure login requests are at least 2 seconds part.
  LOGIN_THROTTLE_SECONDS = 2

  # Helper logging method
  def log(method, o)
    shared_log('UserController', method, o)
  end

  # Index page that loads user.erb
  get '/' do
    @users = User.order('id DESC').all
    @logged_in_user = User.get_user(id: session[:user_id])
    @latest_status_message = session[:status]
    erb :user
  end

  def is_user_logged_in
    return session.has_key?('user_id')
  end

  def get_logged_in_user
    return @logged_in_user
  end

  def redirect_to_index_with_status_msg(msg)
    session[:status] = msg
    redirect '/user'
  end

  # Sends confirmation email to user passed in
  # Confirmation email is HTML-based and is pulled from the views/welcome_email.erb file
  def send_confirmation_email(user, request)
    if user.nil?
      log('send_confirmation_email', 'user is nil')
      return
    end

    if request.nil?
      base_url = 'https://chuckpad-social.herokuapp.com'
    else
      base_url = request.base_url
    end

    log('send_confirmation_email', base_url)

    subject = 'Welcome to ChuckPad!'
    html_body = erb :welcome_email, locals: { username: user.username, confirm_link: base_url.to_s + '/user/confirm/' + user.confirm_token }

    MailHelper.send_email(user.email, subject, html_body)

    log('send_confirmation_email', 'Confirmation email sent to ' + user.email)
  end

  # Sends confirmation email for the currently logged in user. Will NOT send an email if the user has already confirmed
  # their email.
  get '/confirm_email/?' do
    if from_native_client(request)
      logged_in_user = User.get_user(username: params[:username_or_email], email: params[:username_or_email])
    else
      logged_in_user = User.get_user(id: session[:user_id])
    end

    if logged_in_user.nil?
      log('confirm_email', 'No logged in user found')
      redirect_to_index_with_status_msg('Unable to send confirmation email until a user logs in')
    end

    if logged_in_user.email_confirmed
      log('confirm_email', 'User has already confirmed email')
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

    existing_user = User.get_user(username: username, email: email)
    unless existing_user.nil?
      log('create_user', 'user already exists for username = ' + username + '; email = ' + email)

      if from_native_client(request)
        if existing_user.email == email && existing_user.username == username
          fail_with_json_msg(500, 'A user with that email address and username already exists.')
        elsif existing_user.email == email
          fail_with_json_msg(500, 'A user with that email address already exists.')
        else
          fail_with_json_msg(500, 'A user with that username already exists.')
        end
        return
      else
        redirect_to_index_with_status_msg('Unable to create user because user already exists')
      end
    end

    # No user found so we can validate inputs and create a user

    # Check for username, password, and email being present
    if username.blank? || password.blank? || email.blank?
      log('create_user', 'one or more params are empty')
      if from_native_client(request)
        fail_with_json_msg(500, 'Username, password, and email are all required')
        return
      else
        redirect_to_index_with_status_msg('Username, password, and email are all required')
      end
    end

    # Check that username has only valid characters and isn't too long
    unless User.username_is_valid(username)
      log('create_user', 'invalid characters in username ' + username)
      if from_native_client(request)
        fail_with_json_msg(500, 'Invalid characters or length for username')
        return
      else
        redirect_to_index_with_status_msg("Username can only use alphanumeric, period, underscore, and hyphen characters and between #{MIN_USERNAME_LENGTH}-#{MAX_USERNAME_LENGTH} characters")
      end
    end

    # Check password strength
    if User.is_password_weak('create_user', username, password)
      log('create_user', 'password is weak')
      if from_native_client(request)
        fail_with_json_msg(500, 'The password is too weak')
        return
      else
        redirect_to_index_with_status_msg('The password is too weak')
      end
    end

    # Validate email address
    unless EmailValidator.valid?(email)
      log('create_user', 'email is valid')
      if from_native_client(request)
        fail_with_json_msg(500, 'Please enter a valid email')
        return
      else
        redirect_to_index_with_status_msg('Please enter a valid email')
      end
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

    if from_native_client(request)
      success_with_json_msg(user.as_json(nil, auth_token.auth_token))
    else
      redirect_to_index_with_status_msg('User created with id ' + user.id.to_s)
    end
  end

  # Given token passed in url, finds the associated user and flags their email as confirmed
  # NOTE: This is a web-only API and should not be called from native clients
  get '/confirm/:token/?' do
    token = params[:token].to_s

    if token.nil? || token.empty?
      log('confirm/:token/', 'token is nil or empty')
      return
    end

    user = User.get_user(confirm_token: token)

    if user.nil?
      log('confirm/:token/', 'Could not find user for confirm token')
      redirect_to_index_with_status_msg('Unable to find a user with confirm token = ' + token)
    end

    user.email_confirmed = true
    user.save

    redirect_to_index_with_status_msg('Email confirmed for user ' + user.username)
  end

  post '/change_password/?' do
    if from_native_client(request)
      logged_in_user = User.get_user_with_verification(params[:username], params[:email], params[:auth_token])
    else
      logged_in_user = User.get_user(id: session[:user_id])
    end

    if logged_in_user.nil?
      log('change_password', 'No user found')
      if from_native_client(request)
        fail_with_json_msg(500, 'Could not find user')
        return;
      else
        redirect_to_index_with_status_msg('Unable to change password as no user is currently logged in')
      end
    end

    new_password = params[:new_password]
    new_password.strip!

    if User.is_password_weak('change_password', nil, new_password)
      log('change_password', 'password is weak')
      if from_native_client(request)
        fail_with_json_msg(500, 'The password is too weak')
        return
      else
        redirect_to_index_with_status_msg('The password is too weak')
      end
    end

    logged_in_user.salt = BCrypt::Engine.generate_salt
    logged_in_user.password_hash = BCrypt::Engine.hash_secret(new_password, logged_in_user.salt)

    logged_in_user.save

    if from_native_client(request)
      success_with_json_msg('Password updated')
    else
      redirect_to_index_with_status_msg('Password updated')
    end
  end

  # Clears session cookie (web) or invalidates auth token (native clients)
  post '/logout/?' do
    log('logout', params)

    # Logging out on web
    unless from_native_client(request)
      user_id = session[:user_id]
      session[:user_id] = nil
      redirect_to_index_with_status_msg('Logged out user with id ' + user_id.to_s)
    end

    # Logging out on native clients
    token_invalidated = AuthToken.invalidate_token(params[:username], params[:email], params[:auth_token])

    if token_invalidated
      success_with_json_msg('Successfully logged out')
    else
      fail_with_json_msg(500, 'Unable to log user out')
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
      log('login', 'one or more params are empty')
      if from_native_client(request)
        fail_with_json_msg(500, 'Username/email and password are required.')
        return
      else
        redirect_to_index_with_status_msg('Username/email and password are required.')
      end
    end

    user = User.get_user(username: username_or_email, email: username_or_email)

    if user.nil?
      log('login', 'Login failed; no user found')

      error = true
      error_message = 'Unable to find user with details ' + params[:username_or_email]
    end

    # If someone is trying to log in too rapidly, slow them down a bit
    unless error
      unless user.last_login_attempt.nil?
        seconds_since_last_login = (DateTime.now.to_f - user.last_login_attempt.to_f).to_f
        if seconds_since_last_login < LOGIN_THROTTLE_SECONDS
          sleep_length = LOGIN_THROTTLE_SECONDS - seconds_since_last_login
          log('login', "User attempted to login too quickly so sleeping for #{sleep_length} seconds")
          sleep(sleep_length)
        end
      end

      user.last_login_attempt = DateTime.now
      user.save
    end

    unless error
      if user.password_hash == BCrypt::Engine.hash_secret(password, user.salt)
        session[:user_id] = user.id
        # No current notion of session for native clients
      else
        log('login', 'Bad password')

        error = true
        error_message = 'Login failed because of bad password'
      end
    end

    if error
      if from_native_client(request)
        fail_with_json_msg(500, error_message)
        return
      else
        redirect_to_index_with_status_msg(error_message)
      end
    else
      if from_native_client(request)
        auth_token = AuthToken.generate_token(user)
        success_with_json_msg(user.as_json(nil, auth_token.auth_token))
      else
        redirect_to_index_with_status_msg('Logged in successfully')
      end
    end
  end

end
