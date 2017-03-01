require 'coinbase/wallet'

module Docproof
  class PaymentProcessor
    class Coinbase
      class MissingCredentials < ::Docproof::Error; end

      class Configuration
        attr_reader :api_key, :api_secret, :account_id

        def initialize(api_key: nil, api_secret: nil, account_id: nil)
          self.api_key = api_key || ENV['COINBASE_API_KEY']
          self.api_secret = api_secret || ENV['COINBASE_API_SECRET']
          self.account_id = account_id || ENV['COINBASE_ACCOUNT_ID']
        end

        private

        attr_writer :api_key, :api_secret, :account_id
      end

      attr_reader :recipient, :amount

      def self.configure(api_key: nil, api_secret: nil, account_id: nil)
        @configuration = Configuration.new(api_key: api_key,
                                           api_secret: api_secret,
                                           account_id: account_id)
      end

      def self.clear_configuration
        @configuration = Configuration.new
      end

      class << self
        attr_reader :configuration

        private

        attr_writer :configuration
      end

      def initialize(recipient:, amount:)
        configuration = Coinbase.configuration || Configuration.new
        if !configuration.api_key || !configuration.api_secret
          raise MissingCredentials, 'Coinbase API key and secret in not set'
        end

        @recipient = recipient
        @amount    = amount
      end

      def perform!
        coinbase_wallet_account.send(
          to:       recipient,
          amount:   amount,
          currency: 'BTC'
        )
      end

      private

      def coinbase_client
        @coinbase_client ||= begin
          configuration = Coinbase.configuration
          ::Coinbase::Wallet::Client.new(api_key: configuration.api_key,
                                         api_secret: configuration.api_secret)
        end
      end

      def coinbase_wallet_account
        @coinbase_wallet_account ||= begin
          account_id = Coinbase.configuration.account_id
          if account_id && account_id != ''
            coinbase_client.account(account_id)
          else
            coinbase_client.primary_account
          end
        end
      end
    end
  end
end
