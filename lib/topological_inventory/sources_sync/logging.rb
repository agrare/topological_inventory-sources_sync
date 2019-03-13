require "manageiq/loggers"

module TopologicalInventory
  module SourcesSync
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= ManageIQ::Loggers::Container.new
    end

    module Logging
      def logger
        TopologicalInventory::SourcesSync.logger
      end
    end
  end
end
