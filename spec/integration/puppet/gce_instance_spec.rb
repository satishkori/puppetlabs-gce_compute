require 'spec_helper'
require 'helpers/integration_spec_helper'

describe "gce_instance" do
  it_behaves_like "a resource that can be created and destroyed" do
    let(:type_name) { 'gce_instance' }
    let(:gcloud_resource_name) { 'instances' }
    let(:describe_args) { 'puppet-test-instance --zone us-central1-a' }
    let(:expected_properties) { {'name'        => 'puppet-test-instance',
                                 'zone'        => /us-central1-a/,
                                 'description' => "Instance for testing the puppetlabs-gce_compute module",
                                 'machineType' => /f1-micro/,
                                 'canIpForward' => true} }
    let(:other_property_expectations) do
      Proc.new do |out|
        # expect network
        expect(out['networkInterfaces'].size).to eq(1)
        expect(out['networkInterfaces'][0]['network']).to match(/puppet-test-instance-network/)

        # expect address
        address_out = IntegrationSpecHelper.describe_out('addresses', 'puppet-test-instance-address --region us-central1')
        expect(out['networkInterfaces'][0]['accessConfigs'].size).to eq(1)
        expect(out['networkInterfaces'][0]['accessConfigs'][0]['natIP']).to eq(address_out['address'])

        # expect maintenance_policy
        expect(out['scheduling']['onHostMaintenance']).to match('TERMINATE')

        # expect tags
        expect(out['tags']['items']).to match_array(['tag1', 'tag2'])

        # expect metadata
        expect(out['metadata']['items']).to include({'key'   => 'test-metadata-key',
                                                     'value' => 'test-metadata-value'})

        # expect startup_script
        startup_script_metadata = out['metadata']['items'].select { |item| item['key'] == 'startup-script' }[0]
        expect(startup_script_metadata).not_to be_nil
        expect(startup_script_metadata['value']).to match(/an example startup script that does nothing/)

        # expect image
        disk_out = IntegrationSpecHelper.describe_out('disks', 'puppet-test-instance --zone us-central1-a')
        expect(disk_out['sourceImage']).to match(/coreos/)

        # expect disk
        instance_from_disk_out = IntegrationSpecHelper.describe_out('instances', 'puppet-test-instance-from-disk --zone us-central1-a')
        expect(instance_from_disk_out['disks'].size).to eq(1)
        expect(instance_from_disk_out['disks'][0]['source']).to match(/puppet-test-instance-from-disk-disk/)
      end
    end
  end
end
