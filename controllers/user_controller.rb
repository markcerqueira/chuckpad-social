require './controllers/application_controller'
require 'bcrypt'

class UserController < ApplicationController

  # Helper logging method
  def log(method, o)
    shared_log('UserController', method, o)
  end

  # Find a user by id, username, or email. If multiple params are passed
  # they will search in order declared (e.g. search by id first, username
  # second, email third).
  def get_user(id, username, email)
    user = User.find_by_id(params[id])
    if !user.nil?
      return user
    end

    user = User.find_by_username(params[username])
    if !user.nil?
      return user
    end

    user = User.find_by_email(email)
    if !user.nil?
      return user
    end

    return nil
  end

  # Index page that loads user.erb
  get '/' do
    @users = User.find(:all, :order  => 'id DESC')
    erb :user
  end

  # Creates a new user
  post '/create_user/?' do
    from_web = params[:web].to_s == "1"

    username = params[:user][:username]
    email = params[:user][:email]
    password = params[:password]
    admin = params[:user].has_key?('admin')

    existing_user = get_user(nil, username, email)

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

  # Deletes user with the passed id
  get '/delete/:id/?' do
    log('delete', params)

    user = get_user(params[:id], nil, nil)

    if user.nil?
      log('delete', 'No user found')
      status 404
      return
    end

    user.delete

    redirect '/user'
  end

  # Logs in as a user
  post '/login/?' do
    user = get_user(nil, params[:username_or_email], params[:username_or_email])

    if user.nil?
      flash[:status] = 'No user found';
      status 404
      return
    end

    if user.password_hash ==  BCrypt::Engine.hash_secret(params[:password], user.salt)
      flash[:status] = 'Success';
    else
      flash[:status] = 'Failed';
    end

    # redirect '/user'
  end

end
