# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'fastlane'
gem 'json'
gem 'lefthook'
gem 'rubocop', '1.38', group: :rubocop_dependencies

eval_gemfile('fastlane/Pluginfile')

group :rubocop_dependencies do
  gem 'rubocop-performance'
  gem 'rubocop-require_tools'
end
