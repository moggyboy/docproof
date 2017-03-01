require 'pry'
require 'spec_helper'
require 'docproof'

module Docproof
  class PaymentProcessor
    class Coinbase
      describe Configuration do
        describe 'initialization' do
          let(:api_key) { nil }
          let(:api_secret) { nil }
          let(:account_id) { nil }
          let(:env) do
            { 'COINBASE_API_KEY' => 'API_KEY',
              'COINBASE_API_SECRET' => 'API_SECRET',
              'COINBASE_ACCOUNT_ID' => 'ACCOUNT_ID' }
          end

          before do
            env.each_pair { |key, value| ENV[key] = value }
            Coinbase.configure(api_key: api_key, api_secret: api_secret,
                               account_id: account_id)
          end

          after do
            env.each_pair { |key, _| ENV[key] = nil }
          end

          subject { Coinbase.configuration }

          describe 'when COINBASE_API_KEY and COINBASE_API_SECRET environment variables defined' do
            it 'takes the API key and secret from environment variable' do
              expect(subject.api_key).to eq env['COINBASE_API_KEY']
              expect(subject.api_secret).to eq env['COINBASE_API_SECRET']
              expect(subject.account_id).to eq env['COINBASE_ACCOUNT_ID']
            end
          end

          describe 'when it is configured with arguments' do
            let(:api_key)    { 'my-coinbase-api-key' }
            let(:api_secret) { 'my-coinbase-api-secret' }
            let(:account_id) { 'my-coinbase-account-id' }

            it 'use the configuration instead of the environment variable' do
              expect(subject.api_key).to eq api_key
              expect(subject.api_secret).to eq api_secret
              expect(subject.account_id).to eq account_id
            end
          end
        end
      end
    end

    describe Coinbase do
      let(:recipient) { 'bitcoinADDRESS' }
      let(:amount)    { 5_000_000 }
      let(:api_key)    { 'my-coinbase-api-key' }
      let(:api_secret) { 'my-coinbase-api-secret' }
      let(:account_id) { 'my-coinbase-account-id' }

      before do
        Coinbase.configure(api_key: api_key, api_secret: api_secret,
                           account_id: account_id)
      end

      subject(:coinbase_instance) { Coinbase.new(recipient: recipient, amount: amount) }

      describe '#new' do
        describe 'when COINBASE_API_KEY and COINBASE_API_SECRET environment variables undefined' do
          let(:api_key)    { nil }
          let(:api_secret) { nil }
          let(:account_id) { nil }

          it 'raise `MissingCredentials`' do
            expect { coinbase_instance }.to raise_error Coinbase::MissingCredentials
          end
        end
      end

      describe '#perform!' do
        describe 'no account id specified' do
          let(:account_id) { nil }
          let(:account) { instance_double(::Coinbase::Wallet::Account) }
          let(:client) { instance_double(::Coinbase::Wallet::Client) }

          it 'call `Coinbase::Wallet::Client#primary_account` to `send` bitcoin' do
            allow(::Coinbase::Wallet::Client).to receive(:new).and_return(client)
            allow(client).to receive(:primary_account).and_return(account)
            expect(account)
              .to receive(:send)
              .with(to: 'bitcoinADDRESS', amount: 5_000_000, currency: 'BTC')
            coinbase_instance.perform!
          end
        end

        describe 'account id specified' do
          let(:account) { instance_double(::Coinbase::Wallet::Account) }
          let(:client) { instance_double(::Coinbase::Wallet::Client) }

          it 'call `Coinbase::Wallet::Client#primary_account` to `send` bitcoin' do
            allow(::Coinbase::Wallet::Client).to receive(:new).and_return(client)
            allow(client).to receive(:account).with(account_id).and_return(account)
            expect(account)
              .to receive(:send)
              .with(to: 'bitcoinADDRESS', amount: 5_000_000, currency: 'BTC')
            coinbase_instance.perform!
          end
        end
      end
    end
  end
end
