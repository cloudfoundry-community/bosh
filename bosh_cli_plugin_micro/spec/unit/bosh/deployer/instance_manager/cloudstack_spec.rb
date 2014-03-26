require 'spec_helper'
require 'fog'
require 'fog/cloudstack/models/compute/servers'
require 'fog/cloudstack/models/compute/ipaddresses'
require 'bosh/deployer/instance_manager/cloudstack'
require 'bosh/deployer/registry'

module Bosh::Deployer
  describe InstanceManager::Cloudstack do
    subject(:cloudstack) { described_class.new(instance_manager, config, logger) }

    let(:instance_manager) { instance_double('Bosh::Deployer::InstanceManager') }

    let(:config) do
      instance_double(
        'Bosh::Deployer::Configuration',
        cloud_options: {
          'properties' => {
            'registry' => {
              'endpoint' => 'fake-registry-endpoint',
            },
            'cloudstack' => {
              'private_key' => 'fake-private-key',
            },
          },
        },
      )
    end

    let(:logger) { instance_double('Logger', info: nil) }

    before { allow(Registry).to receive(:new).and_return(registry) }
    let(:registry) { instance_double('Bosh::Deployer::Registry') }

    before { allow(File).to receive(:exists?).with(/\/fake-private-key$/).and_return(true) }

    describe '#client_services_ip' do
      before do
        allow(config).to receive(:client_services_ip).
                           and_return('fake-client-services-ip')
      end

      context 'when there is a bosh VM' do
        let(:instance) { instance_double('Fog::Compute::Cloudstack::Server') }
        let(:floating_address) { instance_double('Fog::Compute::Cloudstack::Ipaddress') }

        before do
          allow(instance).to receive(:id).and_return('fake-vm-cid')
          allow(instance).to receive(:nics).and_return([{ 'ipaddress' => 'fake-private-ip' }])
          instance_manager.stub_chain(:state, :vm_cid).and_return('fake-vm-cid')
          instance_manager.stub_chain(:cloud, :compute, :servers, :get).and_return(instance)
        end

        context 'when there is a floating ip' do
          before do
            instance_manager.stub_chain(:cloud, :compute, :ipaddresses)
              .and_return([floating_address])
            allow(floating_address).to receive(:virtual_machine_id).
                                 and_return('fake-vm-cid')
            allow(floating_address).to receive(:ip_address).
                                 and_return('fake-floating-ip')
          end

          it 'returns the floating ip' do
            expect(subject.client_services_ip).to eq('fake-floating-ip')
          end
        end

        context 'when there is no floating ip' do
          before do
            instance_manager.stub_chain(:cloud, :compute, :ipaddresses)
              .and_return([])
          end

          it 'returns the private ip' do
            expect(subject.client_services_ip).to eq('fake-private-ip')
          end
        end
      end

      context 'when there is no bosh VM' do
        before { instance_manager.stub_chain(:state, :vm_cid).and_return(nil) }

        it 'returns client services ip according to the configuration' do
          expect(subject.client_services_ip).to eq('fake-client-services-ip')
        end
      end
    end

    describe '#agent_services_ip' do

      context 'when there is a bosh VM' do
        let(:instance) { instance_double('Fog::Compute::Cloudstack::Server') }

        before do
          instance_manager.stub_chain(:state, :vm_cid).and_return('fake-vm-cid')
          instance_manager.stub_chain(:cloud, :compute, :servers, :get).and_return(instance)
          allow(instance).to receive(:nics).and_return([{ 'ipaddress' => 'fake-private-ip' }])
        end

        it 'returns the private ip' do
          expect(subject.agent_services_ip).to eq('fake-private-ip')
        end
      end

      context 'when there is no bosh VM' do
        before do
          instance_manager.stub_chain(:state, :vm_cid).and_return(nil)
          allow(config).to receive(:agent_services_ip).
                             and_return('fake-agent-services-ip')
        end

        it 'returns client services ip according to the configuration' do
          expect(subject.agent_services_ip).to eq('fake-agent-services-ip')
        end
      end
    end

    describe '#internal_services_ip' do
      before do
        allow(config).to receive(:internal_services_ip).
                           and_return('fake-internal-services-ip')
      end

      it 'returns internal services ip according to the configuration' do
        expect(subject.internal_services_ip).to eq('fake-internal-services-ip')
      end
    end
  end
end
