require "betfair/api/rest"
require "betfair/api/rpc"
require "betfair/utils"
require "httpi"

module Betfair
  class Client
    include Utils

    DEFAULT_SETTINGS = { retries: 1 }
    OPERATIONS = {
      betting: [:list_event_types, :list_events, :list_market_catalogue,
                :list_market_book, :list_competitions, :list_market_profit_and_loss,
                :list_countries, :list_current_orders, :list_cleared_orders,
                :list_market_types, :list_time_ranges, :list_venues, :place_orders,
                :cancel_orders, :replace_orders, :update_orders],
      account: [:get_account_funds]
    }

    attr_accessor :settings, :persistent_headers

    def initialize(headers = {}, api_type = :rest, settings = {})
      @settings = DEFAULT_SETTINGS.merge(settings)
      @persistent_headers = {}
      @persistent_headers.merge!(headers)
      extend_api(api_type)
    end

    private

      [:get, :post].each do |verb|
        define_method(verb) do |*args|
          request = configure_request(*args)
          response = attempt((settings[:retries] || 1).times) do
            HTTPI.request(verb, request, settings[:adapter])
          end
          response.body
        end
      end

      def configure_request(opts = {})
        opts[:headers] = persistent_headers.merge(opts[:headers] || {})
        request = HTTPI::Request.new(opts)

        # It would be nice to have HTTPI do this itself but HTTPI::Request#mass_assign doesn't merge auth fields
        unless opts[:cert_file_path].nil? or opts[:cert_key_file_path].nil?
          request.auth.ssl.cert_key_file = opts[:cert_key_file_path]
          request.auth.ssl.cert_file = opts[:cert_file_path]
        end
        request
      end

      def extend_api(type)
        case type
        when :rest
          extend API::REST
        when :rpc
          extend API::RPC
        else
          extend type
        end
      end
  end
end