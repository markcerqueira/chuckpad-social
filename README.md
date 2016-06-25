## chuckpad-social

> "We have no nation, no philosophy, no ideology. We go where we're needed, chucking not for country, not for government, but for ourselves. We need no reason to chuck. We chuck because we are needed. We will be the deterrent for those with no other recourse. We are chuckers without borders, our purpose defined by the era we live in."
> 
> ― Big Boss

Visit [chuckpad-social on Heroku][2]. chuckpad-social is built using lots of stuff including Sinatra, ActiveRecord, and Postgres. 

### Setup
* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuckpad-social directory, you may be prompted to install the right version of Ruby. Do so if needed. Example: `rvm install ruby-2.3.1`
* Install the rest of the gems: `ARCHFLAGS="-arch x86_64" bundle install`
* Install Postgres and create the database if you have not yet. `psql` and then `CREATE DATABASE chuckpad-social;`
* Run `bundle exec rake db:migrate` to run all migrations on the database.
* `bundle exec rerun 'rackup -p 9292'`
* Locally visit [localhost:9292](http://localhost:9292/). As files are changed the rerun gem will automatically reload the app.
* If you need to reset database on Heroku: `heroku pg:reset DATABASE --app chuckpad-social` and then `heroku run rake db:migrate --app chuckpad-social`

### To Add To README
* Set environmental variable RACK_COOKIE_SECRET on Heroku

### Links
* https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
* https://gist.github.com/macek/610596#file-new-html-erb-L2
* https://eggerapps.at/postico/
* https://www.sitepoint.com/build-a-sinatra-mvc-framework/
* http://www.sinatrarb.com/intro.html
* https://html5boilerplate.com/

[1]: http://postgresapp.com/
[2]: http://chuckpad-social.herokuapp.com/
