require "manageiq/loggers"

module TopologicalInventory
  class << self
    attr_writer :logger
  end

  def self.logger
    @logger ||= ManageIQ::Loggers::Container.new
  end

  module Logging
    def logger
      TopologicalInventory.logger
    end
  end
end
