# frozen_string_literal: true
module FakestoreApiService
  # Main Fakestore client using Faraday
  class Client
    # See https://dry-rb.org/gems/dry-initializer/3.0/skip-undefined/
    extend Dry::Initializer[undefined: false]

    RETRY_MAX = 10
    RETRY_INTERVAL = 1
    RETRY_INTERVAL_RANDOMNESS = 0.5
    RETRY_BACKOFF_FACTOR = 1.1

    option :retry_max, default: proc { RETRY_MAX }
    option :retry_interval, default: proc { RETRY_INTERVAL }
    option :retry_interval_randomness, default: proc { RETRY_INTERVAL_RANDOMNESS }
    option :retry_backoff_factor, default: proc { RETRY_BACKOFF_FACTOR }

    option :logger, default: proc { Logger.new(nil) }
    option :connection, default: proc { build_connection }

    def request_get_carts
      log_request('GET', '/carts') do
        connection.get('/carts')
      end
    end

    def request_get_user(user_id)
      log_request('GET', "/users/#{user_id}") do
        connection.get("/users/#{user_id}")
      end
    end

    def request_get_product(product_id)
      log_request('GET', "/products/#{product_id}") do
        connection.get("/products/#{product_id}")
      end
    end

    private

    def build_connection
      Faraday.new(url: 'https://fakestoreapi.com') do |conn|
        conn.use Faraday::Response::RaiseError

        conn.request :url_encoded
        conn.request :retry, retry_options

        conn.response :logger, logger, headers: true, bodies: true, log_level: :debug
        conn.response :json, content_type: /\bjson$/

        conn.ssl.verify = false
        conn.ssl.verify_mode = OpenSSL::SSL::VERIFY_NONE

        conn.adapter Faraday.default_adapter
      end
    end

    def retry_options
      {
        max: retry_max,
        interval: retry_interval,
        interval_randomness: retry_interval_randomness,
        backoff_factor: retry_backoff_factor,
        retry_statuses: [401, *Faraday::Response::RaiseError::ServerErrorStatuses],
        exceptions: [Faraday::ConnectionFailed, Faraday::SSLError, *Faraday::Request::Retry::DEFAULT_EXCEPTIONS],
        methods: [:post, *Faraday::Request::Retry::IDEMPOTENT_METHODS]
      }
    end

    def log_request(method, path)
      start_time = Time.now
      response = yield
      duration = Time.now - start_time

      logger.info(
        "[FakeStoreAPI] #{method} #{path} - " \
        "Status: #{response.status} - " \
        "Duration: #{duration.round(2)}s"
      )

      response
    end
  end
end
