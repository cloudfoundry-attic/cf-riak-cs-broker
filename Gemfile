source "https://rubygems.org"

ruby '2.0.0'

gem 'addressable'
gem 'fog', git: 'https://github.com/cf-blobstore-eng/fog', branch: 'development'
gem 'sinatra'
gem 'unf'
gem 'settingslogic'
gem 'cf-registrar', git: 'https://github.com/cloudfoundry/cf-registrar'
gem 'nats'

group :test do
  gem 'rake'
  gem 'rack-test', require: 'rack/test'
  gem 'rspec'
  gem 'json_spec'
  gem 'codeclimate-test-reporter', require: nil
end

group :development, :test do
  gem 'awesome_print'
  gem 'webmock'
end

group :production do
  gem 'unicorn'
end

