require "topological_inventory/sources_sync"

RSpec.describe TopologicalInventory::SourcesSync do
  let(:parser) { described_class.new(openshift_host: "localhost") }

  context "#process_message" do
    let(:message) do
      OpenStruct.new(
        :payload => {
          "external_tenant" => account_number,
          "source"          => source,
          "payload"         => {
            "vms" => {
              "updated" => [{"id" => 1}, {"id" => 2}],
              "created" => [{"id" => 3}],
              "deleted" => [{"id" => 4}, {"id" => 5}],
            }
          }
        }
      )
    end

    let(:account_number) { "external_tenant_uuid" }
    let(:source) { "source_uuid" }

    let(:sources_sync) do
      TopologicalInventory::SourcesSync.new("localhost", 9092)
    end
  end
end
