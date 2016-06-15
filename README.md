chuck-sinatra
============================================

[chuck-sinatra](http://chuck-sinatra.herokuapp.com/) - Sinatra, ActiveRecord, Postgres, Heroku

* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuck_sinatra directory, you may be prompted to install the right version of Ruby. Do so if needed.
* `gem install bundle`
* `ARCHFLAGS="-arch x86_64" bundle install`
* Install Postgres and run psql -> CREATE DATABASE chuck_sinatra;
* rake db:migrate
* `bundle exec rerun 'rackup -p 9292'`
* [localhost:9292][http://localhost:9292/]

https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
https://gist.github.com/macek/610596#file-new-html-erb-L2
