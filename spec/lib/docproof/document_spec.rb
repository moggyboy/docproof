require 'pry'
require 'spec_helper'
require 'docproof'
require 'docproof/mocks/proof_of_existence'

module Docproof
  describe Document do
    before do
      stub_request(:post, /proofofexistence.com/).to_rack(Mocks::ProofOfExistence::FakeAPI)
    end

    describe '#lookup!' do
      subject(:lookup!) { document.lookup! }

      describe 'looking up a pending hash' do
        let(:document) { described_class.new(:pending) }
        it { is_expected.to be_an_instance_of Hash }

        describe '#response' do
          let(:response) { document.response.keys }

          before { lookup! }

          specify do
            expect(response).not_to include 'tx'
            expect(response).not_to include 'txstamp'
            expect(response).not_to include 'blockstamp'
          end
        end
      end

      describe 'looking up a registered but unconfirmed hash' do
        let(:document) { described_class.new(:registered) }
        it { is_expected.to be_an_instance_of Hash }

        describe '#response' do
          let(:response) { document.response.keys }

          before { lookup! }

          specify do
            expect(response).to include 'tx'
            expect(response).to include 'txstamp'
            expect(response).not_to include 'blockstamp'
          end
        end
      end

      describe 'looking up a registered and confirmed hash' do
        let(:document) { described_class.new(:confirmed) }
        it { is_expected.to be_an_instance_of Hash }

        describe '#response' do
          let(:response) { document.response.keys }

          before { lookup! }

          specify do
            expect(response).to include 'tx'
            expect(response).to include 'txstamp'
            expect(response).to include 'blockstamp'
          end
        end
      end

      describe 'looking up a nonexistent hash' do
        let(:document) { described_class.new(:nonexistent) }
        specify { expect { lookup! }.to raise_error(Document::NotFound) }
      end
    end

    describe '#notarize!' do
      let(:document) { described_class.new(:the_sha256_hash) }
      let(:api_response) { { key: 'value' } }

      subject(:notarize!) { document.notarize! }

      it 'raise `AlreadyNotarized` if the api response include transaction id' do
        allow(document).to receive(:response).and_return('tx' => 'A-TRANSCTION-ID')
        expect { notarize! }.to raise_error described_class::AlreadyNotarized
      end

      it 'call `PaymentProcessor#perform!`' do
        allow(document).to receive(:response).and_return({})
        payment_processor = instance_double(PaymentProcessor)
        expect(PaymentProcessor).to receive(:new).and_return(payment_processor)
        expect(payment_processor).to receive(:perform!)
        notarize!
      end
    end

    describe '#register!' do
      subject(:register!) { document.register! }

      describe 'registering a valid hash' do
        let(:document) { described_class.new(:valid) }
        it { is_expected.to be_an_instance_of Hash }

        describe '#response' do
          let(:response) { document.response.keys }

          before { register! }

          specify do
            expect(response).to include 'digest'
            expect(response).to include 'pay_address'
            expect(response).to include 'price'
          end
        end
      end

      describe 'registering an existing hash' do
        let(:document) { described_class.new(:existing) }
        specify { expect { register! }.to raise_error described_class::Existed }
      end

      describe 'registering an invalid hash' do
        let(:document) { described_class.new(:invalid) }
        specify { expect { register! }.to raise_error described_class::Invalid }
      end
    end
  end
end
