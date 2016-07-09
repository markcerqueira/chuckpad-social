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
      log('create_user', 'user already exists')

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

    user = User.new do |u|
      u.username = username
      u.email = email
      u.admin = admin
      u.salt = BCrypt::Engine.generate_salt
      u.password_hash = BCrypt::Engine.hash_secret(password, u.salt)
    end

    user.save

    if from_native_client(request)
      success_with_json_msg('User created with id ' + user.id.to_s)
    else
      redirect_to_index_with_status_msg('User created with id ' + user.id.to_s)
    end
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
