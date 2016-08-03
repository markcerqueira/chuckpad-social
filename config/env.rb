# This file is gitignored as you should not commit the sensitive data in this
# file to version control. Here is a version that includes all the environmental
# variables you would want to set.
config_env do
  set 'RACK_COOKIE_SECRET', ''

  # Email
  set 'EMAIL_FROM_NAME', ''
  set 'EMAIL_FROM_ADDRESS', ''
  set 'SENDGRID_API_KEY', ''
end
