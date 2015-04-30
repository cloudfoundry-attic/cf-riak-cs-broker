source "https://rubygems.org"

gem 'addressable'
gem 'fog'
gem 'fog-riakcs'
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

group :development do
  gem 'roodi'
end

group :production do
  gem 'unicorn'
end

