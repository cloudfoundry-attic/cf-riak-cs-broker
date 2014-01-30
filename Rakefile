require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir['spec/**/*_spec.rb'].reject{ |f| f['/integration'] }
end

namespace :spec do
  desc "Run the integration specs"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = "spec/integration/*_spec.rb"
  end
end

task :default => :spec
