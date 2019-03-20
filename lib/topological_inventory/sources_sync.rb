require "faktory"
require "topological_inventory/sources_sync/logging"

module TopologicalInventory
  class SourcesSync
    include Logging

    def initialize(faktory_url)
      self.faktory_url = faktory_url
    end

    def run
      logger.info("Starting Sources sync...")

      initial_sources_sync

      loop do
        work = faktory_client.fetch("platform.sources.event-stream")
        next if work.nil?

        perform_work(work)
      end
    end

    private

    attr_accessor :faktory_url

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

    def perform_work(work)
      jobtype, args = work.values_at("jobtype", "args")
      logger.info("#{jobtype}: #{args}")

      payload = args.first

      case jobtype
      when "Source.create"
        Source.create!(
          :uid    => payload["uid"],
          :tenant => tenants_by_external_tenant(payload["tenant"]),
        )
      when "Source.destroy"
        Source.find_by(:uid => payload["uid"]).destroy
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

    def faktory_client
      @faktory_client ||= Faktory::Client.new(:url => faktory_url)
    end
  end
end
