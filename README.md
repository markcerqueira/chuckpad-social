chuck-sinatra
============================================

[chuck-sinatra](http://chuck-sinatra.herokuapp.com/) - Sinatra, ActiveRecord, Postgres, Heroku

* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuck_sinatra directory, you may be prompted to install the right version of Ruby.
Do so if needed. Example: `rvm install ruby-2.3.1`
* Install the rest of the gems: `ARCHFLAGS="-arch x86_64" bundle install`
* Install Postgres and create the database if you have not yet. `psql` and then `CREATE DATABASE chuck_sinatra;`
* Run `rake db:migrate` to run all migrations on the database.
* `bundle exec rerun 'rackup -p 9292'`
* [localhost:9292][http://localhost:9292/]


* If you need to reset database on Heroku: 
  `heroku pg:reset DATABASE --app chuck-sinatra`
  `heroku run rake db:migrate --app chuck-sinatra`

# Links
* https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
* https://gist.github.com/macek/610596#file-new-html-erb-L2
* https://eggerapps.at/postico/
* https://www.sitepoint.com/build-a-sinatra-mvc-framework/
* http://www.sinatrarb.com/intro.html

[1]: http://postgresapp.com/

