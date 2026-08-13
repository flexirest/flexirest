# IMPORTANT: bundler/setup so a bare `rake spec` runs the same suite as CI's
# `bundle exec rake`. Several specs are defined conditionally on
# Gem.loaded_specs["api-auth"], which only lists *activated* gems - without Bundler
# those guards read false and the examples silently vanish rather than fail.
require "bundler/setup"
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec')

task :console do
  require 'irb'
  require 'irb/completion'
  require './lib/flexirest'
  ARGV.clear
  IRB.start
end
task :c => :console

task :default => :spec
