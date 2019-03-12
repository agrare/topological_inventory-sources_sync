require "concurrent"
require "json"
require "manageiq-messaging"
require 'rest_client'
require "topological_inventory/logging"

module TopologicalInventory
  class SourcesSync
    include Logging

    attr_reader :source, :sns_topic

    def initialize(queue_host, queue_port)
      self.queue_host                = queue_host
      self.queue_port                = queue_port
    end

    def run
      logger.info("Starting Sources sync...")
      client = ManageIQ::Messaging::Client.open(default_messaging_opts.merge(:host => queue_host, :port => queue_port))

      queue_opts = {
        :service     => "platform.sources.event-stream",
        :persist_ref => "sources_sync_worker"
      }

      # Can't use 'subscribe_messages' until https://github.com/ManageIQ/manageiq-messaging/issues/38 is fixed
      # client.subscribe_messages(queue_opts.merge(:max_bytes => 500000)) do |messages|
      begin
        client.subscribe_topic(queue_opts) do |message|
          process_message(message)
        end
      ensure
        client&.close
      end
    end

    private

    attr_accessor :log, :queue_host, :queue_port

    def process_message(message)
      logger.info("#{message.message}: #{message.payload}")
      case message.message
      when "Source.create"
        Source.create!(message.payload.except("id"))
      when "Source.destroy"
        Source.find_by(:uid => message.payload["uid"]).destroy
      end
    rescue => e
      logger.error(e.message)
      logger.error(e.backtrace.join("\n"))
    end

    def default_messaging_opts
      {
        :protocol   => :Kafka,
        :client_ref => "sources-sync-worker",
        :group_ref  => "sources-sync-worker",
      }
    end
  end
end
