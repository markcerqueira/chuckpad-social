Sinatra with ActiveRecord on Heroku Postgres
============================================

This is a simple demonstration of how to make a [Sinatra](http://www.sinatrarb.com/) 
app that runs on Heroku and uses ActiveRecord and Postgres to manage database models.


* Install RVM
* ARCHFLAGS="-arch x86_64" bundle install
* Install Postgres and run psql -> CREATE DATABASE chuck_sinatra;
* rake db:migrate
* bundle exec rackup