# This file is gitignored as you should not commit the sensitive data in this
# file to version control. Here is a version that includes all the environmental
# variables you would want to set.
config_env do
  set 'RACK_COOKIE_SECRET', ''
  set 'EMAIL_USER_NAME', ''
  set 'EMAIL_PASSWORD', ''
  set 'EMAIL_FROM_EMAIL',  ''
  set 'EMAIL_MAIL_SERVER', ''
end
