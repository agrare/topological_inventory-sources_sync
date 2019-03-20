source 'https://rubygems.org'

plugin "bundler-inject", "~> 1.1"
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport"
gem "concurrent-ruby"
gem "faktory_worker_ruby"
gem "manageiq-loggers", "~> 0.1.0"
gem "more_core_extensions"
gem "optimist"
gem "rest-client"

gem "topological_inventory-core", :git => "https://github.com/agrare/topological_inventory-core", :branch => "extract_sources_service"
gem "sources-api-client",         :git => "https://github.com/agrare/sources-api-client-ruby", :branch => "master"

group :development, :test do
  gem "rake"
  gem "rspec-rails"
  gem "simplecov"
  gem "webmock"
end
