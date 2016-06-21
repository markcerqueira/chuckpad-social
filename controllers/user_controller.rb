require './controllers/application_controller'
require 'bcrypt'

class UserController < ApplicationController

  # Helper logging method
  def log(method, o)
    shared_log('UserController', method, o)
  end

  # Index page that loads user.erb
  get '/' do
    @users = User.find(:all, :order  => 'id DESC')
    @logged_in_user = User.get_user(session[:user_id], nil, nil)
    erb :user
  end

  def is_user_logged_in
    return session.has_key?('user_id')
  end

  def get_logged_in_user
    return @logged_in_user
  end

  # Creates a new user
  post '/create_user/?' do
    from_web = params[:web].to_s == "1"

    username = params[:user][:username]
    email = params[:user][:email]
    password = params[:password]
    admin = params[:user].has_key?('admin')

    existing_user = User.get_user(nil, username, email)

    if !existing_user.nil?
      log('create_user', 'user already exists')
      flash[:status] = 'User already exists';
      status 404
      return
    end

    user = User.new do |u|
      u.username = username
      u.email = email
      u.admin = admin
      u.salt = BCrypt::Engine.generate_salt
      u.password_hash = BCrypt::Engine.hash_secret(password, u.salt)
    end

    user.save

    redirect '/user'
  end

  post '/change_password/?' do
    from_web = params[:web].to_s == "1"

    logged_in_user = User.get_user(session[:user_id], nil, nil)

    if logged_in_user.nil?
      log('change_password', 'No user currently logged in')
      status 404

      if from_web
        redirect '/user'
      else
        return
      end
    end

    new_password = params[:password]

    puts new_password

    logged_in_user.salt = BCrypt::Engine.generate_salt
    logged_in_user.password_hash = BCrypt::Engine.hash_secret(new_password, logged_in_user.salt)

    logged_in_user.save

    redirect '/user'
  end

  # Deletes user with the passed id
  get '/delete/:id/?' do
    log('delete', params)

    user = User.get_user(params[:id], nil, nil)

    if user.nil?
      log('delete', 'No user found')
      status 404
      return
    end

    user.delete

    redirect '/user'
  end

  # Clears session cookie
  get '/logout/:id/?' do
    log('logout', params)
    session[:user_id] = nil
    redirect '/user'
  end

  # Logs in as a user
  post '/login/?' do
    user = User.get_user(nil, params[:username_or_email], params[:username_or_email])

    if user.nil?
      log('/login', 'Login failed; no user found')
      status 404
      return
    end

    if user.password_hash ==  BCrypt::Engine.hash_secret(params[:password], user.salt)
      session[:user_id] = user.id
    else
      log('/login', 'Login failed; bad credentials')
    end

    redirect '/user'
  end

end
