## chuckpad-social

> "We have no nation, no philosophy, no ideology. We go where we're needed, **chucking** not for country, not for government, but for ourselves. We need no reason to **chuck**. We **chuck** because we are needed. We will be the deterrent for those with no other recourse. We are **chuckers** without borders, our purpose defined by the era we live in."
> 
> ― Big Boss

### What is chuckpad-social?

chuckpad-social is an upload-download service for ChucK patches in the MiniAudicle for iPad app. The service is designed to help people learn more about ChucK through examples and encourage people to build and share their own creations with the world. Visit [chuckpad-social on Heroku][2]. chuckpad-social has an [iOS library][6] that wraps its API. Although originally designed with ChucK and MiniAudicle in mind, you can use chuckpad-social to share anything and the service supports hosting different types of data! chuckpad-social is built using lots of stuff including Sinatra, ActiveRecord, Postgres, and lots of gems developed by the vibrant Ruby community. 

### Setup
* Install RVM: `\curl -sSL https://get.rvm.io | bash`
* When you cd into the chuckpad-social directory, you may be prompted to install the right version of Ruby. Do so if needed. Example: `rvm install ruby-2.3.1`
* If you just installed a new version of Ruby, you'll likely need to get the bundler gem first: `gem install bundle`
* Install the rest of the gems: `ARCHFLAGS="-arch x86_64" bundle install` If you are getting errors running this, try running `xcode-select --install` as this has [cleared up issues for other people][3].
* Install [Postgres][4] and create the database if you have not yet. On the command-line, run `psql` and then `CREATE DATABASE "chuckpad-social";`
* Run `bundle exec rake db:migrate` to run all migrations on the database.
* Run the service locally: `bundle exec rerun 'rackup -p 9292'`.
* Locally visit [localhost:9292](http://localhost:9292/). If you see connection errors when you visit this page, you need to lanuch the Postgres app! As files are changed the rerun gem will automatically reload the app.
* If you need to reset database on Heroku: `heroku pg:reset DATABASE --app chuckpad-social --confirm chuckpad-social` and then `heroku run rake db:migrate --app chuckpad-social`. If you need to reset the database locally, run `psql` and then `DROP DATABASE chuckpad-social;`.

### Contribute
Improvements are appreciated and always welcome! If you'd like to work on features on the roadmap, feel free to view our [project task page on Asana][5]. You'll need to log into your Asana account.

### Related Repositories
* [hello-chuckpad][8] is a "Hello, World" project that uses this service with a suite of unit tests to verify the interactions between this iOS library and the service. 
* [chuckpad-social-ios][9] is the iOS API that interacts with this service.
* [miniAudicle][10] is the first iOS app that uses the chuckpad-social service.

### Heroku Config Variables

If you deploy your own instance of chuckpad-social on Heroku, you'll need to set a few config variables to get everything working nicely.

* RACK_COOKIE_SECRET - random string used to [ensure integrity of cookie data][11] when logging in on web
* RACK_ENV - should be `production` or `stage`
* SENDGRID_API_KEY - API key from the Sendgrid service which is used to send confirmation and password reset emails
* EMAIL_FROM_ADDRESS - Email address shown on emails sent via Sendgrid (e.g. welcome@test.app)
* EMAIL_FROM_NAME - Name shown on emails sent via Sendgrid (e.g. ChuckPad Mailer)

These are automatically set by Heroku and can be left alone:

* DATABASE_URL - database URL that you can use to connect directly to the database (format of URL is postgres://user:password@host:port/database)
* LANG

### README TODOs
* Add [SPF record][7] to avoid Gmail's "message is authenticated" warning
* Publish config/env.rb to Heroku with `rake config_env:heroku[chuckpad-social]`
* You need a `config/env.rb` file to get cookies and email sending working properly locally.

### Links and Resources
* https://www.sitepoint.com/rails-userpassword-authentication-from-scratch-part-i/
* https://gist.github.com/macek/610596#file-new-html-erb-L2
* https://eggerapps.at/postico/
* https://www.sitepoint.com/build-a-sinatra-mvc-framework/
* http://www.sinatrarb.com/intro.html
* https://html5boilerplate.com/
* https://github.com/SergXIIIth/config_env
* https://github.com/mikel/mail
* https://coderwall.com/p/u56rra/ruby-on-rails-user-signup-email-confirmation-tutorial

[1]: http://postgresapp.com/
[2]: http://chuckpad-social.herokuapp.com/
[3]: https://github.com/sparklemotion/nokogiri/issues/1483#issuecomment-224684394
[4]: https://www.postgresql.org/download/
[5]: https://app.asana.com/-/share?s=147252256199690-lWxuO8hBjVq7jOGkmVlwpUpsPfvH9ekYGQToiw1dMUP-868703070985
[6]: https://github.com/markcerqueira/chuckpad-social-ios
[7]: https://help.dreamhost.com/hc/en-us/articles/220854287-What-SPF-records-do-I-use-
[8]: https://github.com/markcerqueira/hello-chuckpad
[9]: https://github.com/markcerqueira/chuckpad-social-ios
[10]: https://github.com/ccrma/miniAudicle
[11]: http://www.rubydoc.info/github/rack/rack/Rack/Session/Cookie
