require "manageiq-messaging"
require "topological_inventory/sources_sync/worker"

RSpec.describe TopologicalInventory::SourcesSync::Worker do
  context "#process_message" do
    let(:sources_sync) do
      described_class.new("localhost", 9092)
    end
    let(:message)         { ManageIQ::Messaging::ReceivedMessage.new(nil, event, payload, nil) }
    let(:external_tenant) { SecureRandom.uuid }
    let(:payload) do
      {"name" => "AWS", "source_type_id" => "1", "tenant" => external_tenant, "uid" => SecureRandom.uuid, "id" => "1"}
    end

    context "source create event" do
      let(:event) { "Source.create" }
      context "with no existing tenants" do
        it "creates a source and a new tenant" do
          sources_sync.send(:process_message, message)

          expect(Source.count).to eq(1)
          expect(Source.first.uid).to eq(payload["uid"])
          expect(Tenant.count).to eq(1)
          expect(Tenant.first.external_tenant).to eq(payload["external_tenant"])
        end
      end

      context "with an existing tenant" do
        let(:tenant) { Tenant.find_or_create_by(:external_tenant => payload["external_tenant"]) }

        it "creates a source on an existing tenant" do
          sources_sync.send(:process_message, message)

          expect(Source.count).to eq(1)
          expect(Source.first.uid).to eq(payload["uid"])
          expect(Tenant.count).to eq(1)
          expect(Tenant.first.external_tenant).to eq(payload["external_tenant"])
        end
      end
    end

    context "source destroy event" do
      let(:event) { "Source.destroy" }
      let(:tenant) { Tenant.find_or_create_by(:external_tenant => payload["external_tenant"]) }
      let!(:source) { Source.create!(:tenant => tenant, :uid => payload["uid"]) }
      let(:payload) do
        {"name" => "AWS", "source_type_id" => "1", "tenant" => SecureRandom.uuid, "uid" => SecureRandom.uuid, "id" => "1"}
      end

      it "deletes the source" do
        sources_sync.send(:process_message, message)
        expect(Source.count).to eq(0)
      end
    end
  end
end
