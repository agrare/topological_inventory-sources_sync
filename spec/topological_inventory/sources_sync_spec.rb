require "manageiq-messaging"
require "topological_inventory/sources_sync"

RSpec.describe TopologicalInventory::SourcesSync do
  context "#process_message" do
    let(:sources_sync) do
      TopologicalInventory::SourcesSync.new("localhost", 9092)
    end
    let(:message) { ManageIQ::Messaging::ReceivedMessage.new(nil, event, payload, nil) }

    context "source create event" do
      let(:event) { "Source.create" }
      let(:patyload) do
        {"name" => "AWS", "source_type_id" => "1", "tenant_id" => "1", "uid" => "12c48843-0948-4539-b420-089dd1bec280", "id" => "1"}
      end
    end

    context "source destroy event" do
      let(:event) { "Source.destroy" }
      let(:payload) { {"id"=>"1"} }
    end
  end
end
