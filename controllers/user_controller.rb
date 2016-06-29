require './controllers/application_controller'
require 'bcrypt'

class UserController < ApplicationController

  # Helper logging method
  def log(method, o)
    shared_log('UserController', method, o)
  end

  # Index page that loads user.erb
  get '/' do
    @users                 = User.order(id: :desc).all
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

  # Creates a new user
  post '/create_user/?' do
    username = params[:user][:username]
    email = params[:user][:email]
    password = params[:password]
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
    logged_in_user = nil;

    if from_native_client(request)
      logged_in_user = User.get_user(nil, params[:username_or_email], params[:username_or_email])
    else
      logged_in_user = User.get_user(session[:user_id], nil, nil)
    end

    # TODO Check password length

    if logged_in_user.nil?
      log('change_password', 'No user found')
      if from_native_client(request)
        fail_with_json_msg(500, 'Could not find user')
        return;
      else
        redirect_to_index_with_status_msg('Unable to change password as no user is currently logged in')
      end
    end

    logged_in_user.salt = BCrypt::Engine.generate_salt
    logged_in_user.password_hash = BCrypt::Engine.hash_secret(params[:password], logged_in_user.salt)

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

    error = false
    error_message = nil

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
