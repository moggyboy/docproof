require 'pry'
require 'spec_helper'
require 'docproof'

module Docproof
  describe PaymentProcessor do
    let(:options) { {} }
    let(:processor) { described_class.new(options) }

    describe '#bitcoin_address' do
      subject { processor.bitcoin_address }

      context 'using pay_address' do
        let(:options) { { 'pay_address' => 'bitcoinADDRESS' } }
        it { is_expected.not_to be_nil }
      end

      context 'using payment_address' do
        let(:options) { { 'payment_address' => 'bitcoinADDRESS' } }
        it { is_expected.not_to be_nil }
      end
    end

    describe '#price_in_btc' do
      subject { processor.price_in_btc }


      context 'price set in options' do
        let(:options) { { 'price' => 5_000_000 } }
        it { is_expected.to eq(options['price'].to_f / described_class::BTC_IN_SATOSHIS) }
      end

      it { is_expected.to eq described_class::MINIMUM_PRICE_IN_BTC }
    end

    describe '#perform!' do
      let(:bitcoin_address) { 'bitcoinADDRESS' }
      let(:price_in_btc)    { 500_000 }

      subject(:perform!) { processor.perform! }

      it 'call `Coinbase#perform!`' do
        coinbase = instance_double(PaymentProcessor::Coinbase)
        expect(PaymentProcessor::Coinbase).to receive(:new).and_return(coinbase)
        expect(coinbase).to receive(:perform!)
        perform!
      end
    end
  end
end
