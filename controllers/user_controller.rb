require './controllers/application_controller'

class UserController < ApplicationController

  MIN_PASSWORD_ENTROPY = 6

  # Helper logging method
  def log(method, o)
    shared_log('UserController', method, o)
  end

  # Index page that loads user.erb
  get '/' do
    @users                 = User.order('id DESC').all
    @logged_in_user        = User.get_user(session[:user_id], nil, nil)
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

  # Simple password checker to make sure password is not equal to username and not weak
  def is_password_weak(caller, username, password)
    if password.nil? or password.length == 0
      log(caller, 'password is empty')
      return true
    end

    if !username.nil? and password.eql? username
      log(caller, 'password is the same as username')
      return true
    end

    password_entropy = StrongPassword::StrengthChecker.new(password).calculate_entropy
    log(caller, 'password.length = ' + password.length.to_s + '; password_entropy = '+  password_entropy.to_s)
    return password_entropy.to_i < MIN_PASSWORD_ENTROPY
  end

  # Sends confirmation email to user passed in
  # Confirmation email is HTML-based and is pulled from the views/welcome_email.erb file
  def send_confirmation_email(user, request)
    if user.nil?
      log('send_confirmation_email', 'user is nil')
      return
    end

    subject = 'Welcome to ChuckPad!'
    html_body = erb :welcome_email, locals: { username: user.username, confirm_link: request.base_url.to_s + '/user/confirm/' + user.confirm_token }

    MailHelper.send_email(user.email, subject, html_body)

    log('send_confirmation_email', 'Confirmation email sent to ' + user.email)
  end

  # Sends confirmation email for the currently logged in user. Will NOT send an email if the user has already confirmed
  # their email.
  get '/confirm_email/?' do
    if from_native_client(request)
      logged_in_user = User.get_user(nil, params[:username_or_email], params[:username_or_email])
    else
      logged_in_user = User.get_user(session[:user_id], nil, nil)
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

    existing_user = User.get_user(nil, username, email)
    unless existing_user.nil?
      log('create_user', 'user already exists for username = ' + username + '; email = ' + email)

      if from_native_client(request)
        fail_with_json_msg(500, 'Unable to create user because user already exists')
        return
      else
        redirect_to_index_with_status_msg('Unable to create user because user already exists')
      end
    end

    # No user found so we can validate inputs and create a user

    # Check for username, password, and email being present
    if username.blank? or password.blank? or email.blank?
      log('create_user', 'one or more params are empty')
      if from_native_client(request)
        fail_with_json_msg(500, 'Username, password, and email are all required')
        return
      else
        redirect_to_index_with_status_msg('Username, password, and email are all required')
      end
    end

    # Check password strength
    if is_password_weak('create_user', username, password)
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

    send_confirmation_email(user, request)

    if from_native_client(request)
      success_with_json_msg('User created with id ' + user.id.to_s + '. Confirmation email sent to ' + user.email.to_s)
    else
      redirect_to_index_with_status_msg('User created with id ' + user.id.to_s)
    end
  end

  # Given token passed in url, finds the associated user and flags their email as confirmed
  # NOTE: This is a web-only API and should not be called from native clients
  get '/confirm/:token/?' do
    token = params[:token].to_s

    if token.nil? or token.empty?
      log('confirm/:token/', 'token is nil or empty')
      return
    end

    user = User.get_user(nil, nil, nil, token)

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
      logged_in_user = User.get_user(nil, params[:username_or_email], params[:username_or_email])
    else
      logged_in_user = User.get_user(session[:user_id], nil, nil)
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

    password = params[:password]
    password.strip!

    if is_password_weak('change_password', nil, password)
      log('change_password', 'password is weak')
      if from_native_client(request)
        fail_with_json_msg(500, 'The password is too weak')
        return
      else
        redirect_to_index_with_status_msg('The password is too weak')
      end
    end

    logged_in_user.salt = BCrypt::Engine.generate_salt
    logged_in_user.password_hash = BCrypt::Engine.hash_secret(password, logged_in_user.salt)

    logged_in_user.save

    if from_native_client(request)
      success_with_json_msg('Password updated')
    else
      redirect_to_index_with_status_msg('Password updated')
    end
  end

  # Deletes user with the passed id
  get '/delete/:id/?' do
    log('delete', params)

    user = User.get_user(params[:id], nil, nil)

    if user.nil?
      log('delete', 'No user found')
      unless from_native_client(request)
        redirect_to_index_with_status_msg('No user found with id ' + params[:id].to_s)
      end
    end

    user.delete

    unless from_native_client(request)
      redirect_to_index_with_status_msg('User deleted with id ' + user.id.to_s)
    end
  end

  # Clears session cookie
  get '/logout/:id/?' do
    log('logout', params)
    user_id = session[:user_id];
    session[:user_id] = nil
    redirect_to_index_with_status_msg('Logged out user with id ' + user_id.to_s)
  end

  # Logs in as a user
  post '/login/?' do
    user = User.get_user(nil, params[:username_or_email], params[:username_or_email])

    if user.nil?
      log('/login', 'Login failed; no user found')

      error = true
      error_message = 'Unable to find user with details ' + params[:username_or_email]
    end

    unless error
      if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.salt)
        session[:user_id] = user.id
        # No current notion of session for native clients
      else
        log('/login', 'Bad password')

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
      success_msg = 'Logged in successfully'
      if from_native_client(request)
        success_with_json_msg(success_msg)
      else
        redirect_to_index_with_status_msg(success_msg)
      end
    end
  end

end
