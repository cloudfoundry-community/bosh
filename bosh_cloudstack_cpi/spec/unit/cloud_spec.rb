require "spec_helper"
require 'cloud/cloudstack'

describe Bosh::CloudStackCloud::Cloud do

  describe :new do
    end_point = "http://127.0.0.1:5000"
    let(:cloud_options) { mock_cloud_options }
    let(:fog_cloudstack_parms) {
      {
        :provider => 'CloudStack',
        :cloudstack_api_key => 'admin',
        :cloudstack_secret_access_key => 'foobar',
        :cloudstack_scheme => URI.parse(end_point).scheme,
        :cloudstack_host => URI.parse(end_point).host,
        :cloudstack_port => URI.parse(end_point).port,
        :cloudstack_path => URI.parse(end_point).path,
        :connection_options => connection_options,
      }
    }
    let(:connection_options) { nil }
    let(:compute) { double('Fog::Compute') }

    it 'should create a Fog connection' do
      allow(Fog::Compute).to receive(:new).with(fog_cloudstack_parms).and_return(compute)
      zone = double('zone', :network_type => :advanced)
      compute.stub_chain(:zones, :find).and_return(zone)
      cloud = Bosh::CloudStackCloud::Cloud.new(cloud_options['properties'])

      expect(cloud.compute).to eql(compute)
    end

    it 'raises ArgumentError on initializing with blank options' do
      options = Hash.new('options')
      expect {
        Bosh::CloudStackCloud::Cloud.new(options)
      }.to raise_error(ArgumentError, /Invalid CloudStack configuration/)
    end

    it 'raises ArgumentError on initializing with non Hash options' do
      options = 'this is a string'
      expect {
        Bosh::CloudStackCloud::Cloud.new(options)
      }.to raise_error(ArgumentError, /Invalid CloudStack configuration/)
    end

    it 'raises a CloudError exception if cannot connect to the CloudStack Compute API' do
      allow(Fog::Compute).to receive(:new).and_raise(Excon::Errors::Unauthorized, 'Unauthorized')
      expect {
        Bosh::CloudStackCloud::Cloud.new(cloud_options['properties'])
      }.to raise_error(Bosh::Clouds::CloudError,
        'Unable to connect to the CloudStack Compute API. Check task debug log for details.')
    end

    it 'raises a CloudError exception if cannot connect to the CloudStack Image Service API' do
      skip 'CloudStack CPI does not initiate Image instance from Image Service API'
    end

    it 'raises a CloudError exception if cannot connect to the CloudStack Volume Service API' do
      skip 'CloudStack CPI does not initiate Volume instance from Volume Service API'
    end

    context 'with connection options' do
      let(:connection_options) {
        JSON.generate({
          'ssl_verify_peer' => false,
        })
      }

      it 'should add optional options to the Fog connection' do
        cloud_options['properties']['cloudstack']['connection_options'] = connection_options
        allow(Fog::Compute).to receive(:new).with(fog_cloudstack_parms).and_return(compute)
        zone = double('zone', :network_type => :advanced)
        compute.stub_chain(:zones, :find).and_return(zone)
        Bosh::CloudStackCloud::Cloud.new(cloud_options['properties'])

        expect(Fog::Compute).to have_received(:new).with(hash_including(connection_options: connection_options))
      end
    end
  end
end
