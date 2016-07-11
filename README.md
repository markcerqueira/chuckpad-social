## chuckpad-social

> "We have no nation, no philosophy, no ideology. We go where we're needed, chucking not for country, not for government, but for ourselves. We need no reason to chuck. We chuck because we are needed. We will be the deterrent for those with no other recourse. We are chuckers without borders, our purpose defined by the era we live in."
> 
> ― Big Boss

### What is chuckpad-social?

chuckpad-social is an upload-download service for ChucK patches. Designed to help people learn more about ChucK through examples and encourage people to build and share their own creations. Visit [chuckpad-social on Heroku][2]. chuckpad-social has an [iOS library][6] that wraps its API. chuckpad-social is built using lots of stuff including Sinatra, ActiveRecord, and Postgres. 

### Setup
* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuckpad-social directory, you may be prompted to install the right version of Ruby. Do so if needed. Example: `rvm install ruby-2.3.1`
* Install the rest of the gems: `ARCHFLAGS="-arch x86_64" bundle install` If you are getting errors running this, try running `xcode-select --install` as this has [cleared up issues for other people][3].
* Install [Postgres][4] and create the database if you have not yet. `psql` and then `CREATE DATABASE chuckpad-social;`
* Run `bundle exec rake db:migrate` to run all migrations on the database.
* `bundle exec rerun 'rackup -p 9292'`
* Locally visit [localhost:9292](http://localhost:9292/). As files are changed the rerun gem will automatically reload the app.
* If you need to reset database on Heroku: `heroku pg:reset DATABASE --app chuckpad-social` and then `heroku run rake db:migrate --app chuckpad-social`


### Contribute
Improvements are appreciated and always welcome! If you'd like to work on features on the roadmap, feel free to view our [project task page on Asana][5] (you'll need to log into your Asana account). 

### README TODOs
* Set environmental variable RACK_COOKIE_SECRET on Heroku
* Add [SPF record][7] to avoid Gmail's "message is authenticated" warning
* Publish config/env.rb to Heroku with `rake config_env:heroku[chuckpad-social]`
* To get git to stop complaining about env.rb if you change it: `git update-index --assume-unchanged config/env.rb`. We are tracking an "empty" version of env.rb so gitignore will sometimes not ignore this file until you tell it to assume its unchanged.

### Links and Resources
* https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
* https://gist.github.com/macek/610596#file-new-html-erb-L2
* https://eggerapps.at/postico/
* https://www.sitepoint.com/build-a-sinatra-mvc-framework/
* http://www.sinatrarb.com/intro.html
* https://html5boilerplate.com/
* https://github.com/SergXIIIth/config_env
* https://github.com/mikel/mail

[1]: http://postgresapp.com/
[2]: http://chuckpad-social.herokuapp.com/
[3]: https://github.com/sparklemotion/nokogiri/issues/1483#issuecomment-224684394
[4]: https://www.postgresql.org/download/
[5]: https://app.asana.com/-/share?s=147252256199690-lWxuO8hBjVq7jOGkmVlwpUpsPfvH9ekYGQToiw1dMUP-868703070985
[6]: https://github.com/markcerqueira/chuckpad-social-ios
[7]: https://help.dreamhost.com/hc/en-us/articles/220854287-What-SPF-records-do-I-use-
