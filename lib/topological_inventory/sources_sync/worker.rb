require "manageiq-messaging"
require "topological_inventory/sources_sync/logging"

module TopologicalInventory
  module SourcesSync
    class Worker
      include Logging

      def initialize(queue_host, queue_port)
        self.queue_host = queue_host
        self.queue_port = queue_port
      end

      def run
        logger.info("Starting Sources sync...")

        initial_sources_sync

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

      attr_accessor :queue_host, :queue_port

      def initial_sources_sync
        sources_by_uid = sources_api_client.list_sources.data.index_by(&:uid)

        current_source_uids  = sources_by_uid.keys
        previous_source_uids = Source.pluck(:uid)

        sources_to_delete = previous_source_uids - current_source_uids
        sources_to_create = current_source_uids - previous_source_uids

        logger.info("Deleting sources [#{sources_to_delete.join("\n")}]") if sources_to_delete.any?
        Source.where(:uid => sources_to_delete).destroy_all

        sources_to_create.each do |source_uid|
          logger.info("Creating source [#{source_uid}]")

          source = sources_by_uid[source_uid]
          tenant = tenants_by_external_tenant(source.tenant)
          Source.create!(
            :tenant => tenant,
            :uid    => source_uid
          )
        end
      end

      def process_message(message)
        logger.info("#{message.message}: #{message.payload}")
        case message.message
        when "Source.create"
          Source.create!(
            :uid    => message.payload["uid"],
            :tenant => tenants_by_external_tenant(message.payload["tenant"]),
          )
        when "Source.destroy"
          Source.find_by(:uid => message.payload["uid"]).destroy
        end
      rescue => e
        logger.error(e.message)
        logger.error(e.backtrace.join("\n"))
      end

      def tenants_by_external_tenant(external_tenant)
        @tenants_by_external_tenant ||= {}
        @tenants_by_external_tenant[external_tenant] ||= Tenant.find_or_create_by(:external_tenant => external_tenant)
      end

      def sources_api_client
        SourcesApiClient::DefaultApi.new
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
end
