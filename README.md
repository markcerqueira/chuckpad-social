## chuck-nation

> "We have no nation, no philosophy, no ideology. We go where we're needed, chucking not for country, not for government, but for ourselves. We need no reason to chuck. We chuck because we are needed. We will be the deterrent for those with no other recourse. We are chuckers without borders, our purpose defined by the era we live in."
> 
> ― Big Boss

Visit [chuck-nation on Heroku][2]. chuck-nation is built using lots of stuff including Sinatra, ActiveRecord, and Postgres. 

### Setup
* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuck-nation directory, you may be prompted to install the right version of Ruby. Do so if needed. Example: `rvm install ruby-2.3.1`
* Install the rest of the gems: `ARCHFLAGS="-arch x86_64" bundle install`
* Install Postgres and create the database if you have not yet. `psql` and then `CREATE DATABASE chuck_sinatra;`
* Run `rake db:migrate` to run all migrations on the database.
* `bundle exec rerun 'rackup -p 9292'`
* Locally visit [localhost:9292](http://localhost:9292/). As files are changed the rerun gem will automatically reload the app.
* If you need to reset database on Heroku: `heroku pg:reset DATABASE --app chuck-nation` and then  `heroku run rake db:migrate --app chuck-nation`

### Links
* https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
* https://gist.github.com/macek/610596#file-new-html-erb-L2
* https://eggerapps.at/postico/
* https://www.sitepoint.com/build-a-sinatra-mvc-framework/
* http://www.sinatrarb.com/intro.html
* https://html5boilerplate.com/

[1]: http://postgresapp.com/
[2]: http://chuck-nation.herokuapp.com/

