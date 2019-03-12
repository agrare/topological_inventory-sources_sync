if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

# For defining kubernetes entities in specs
require "rspec"
require "webmock/rspec"
require "topological_inventory/sources_sync"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
