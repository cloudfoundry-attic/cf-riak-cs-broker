source "https://rubygems.org"

ruby '1.9.3'

gem 'addressable'
gem 'fog', git: 'https://github.com/cf-blobstore-eng/fog', branch: 'development'
gem 'sinatra'
gem 'unf'
gem 'settingslogic'

group :test do
  gem 'rake'
  gem 'rack-test', require: 'rack/test'
  gem 'rspec'
  gem 'json_spec'
end

group :development, :test do
  gem 'awesome_print'
  gem 'webmock'
end
