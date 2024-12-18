# frozen_string_literal: true

module FakestoreApiService
  # Main Fakestore client using Faraday
  class Client
    attr_reader :logger

    def initialize(logger)
      @logger = logger || Logger.new($stdout)
      @client = configure_client
    end

    def request_get_carts
      log_request('GET', '/carts') do
        @client.get('/carts')
      end
    end

    def request_get_user(user_id)
      log_request('GET', "/users/#{user_id}") do
        @client.get("/users/#{user_id}")
      end
    end

    def request_get_product(product_id)
      log_request('GET', "/products/#{product_id}") do
        @client.get("/products/#{product_id}")
      end
    end

    private

    def configure_client
      Faraday.new(
        url: 'https://fakestoreapi.com',
        headers: { 'Content-Type' => 'application/json' },
        ssl: { verify: false }
      ) do |f|
        f.response :json
      end
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
