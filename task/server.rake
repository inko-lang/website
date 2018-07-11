# frozen_string_literal: true

desc 'Builds the website and starts a server'
task :server do
  sh 'bundle exec middleman'
end
