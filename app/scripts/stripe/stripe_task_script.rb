module Scripts
  module Stripe
    # Handles creation of Stripe invoices from FakeStore API data
    class CreateInvoiceStripeScript
      # Initialize with configuration and setup logging
      def initialize
        @logger = Logger.new($stdout)
        @logger.level = Logger::INFO
        configure_stripe
        configure_fakestore_client
      end

      # Main call method
      def call
        begin
          carts_with_users = fetch_carts_with_users
          create_customers(carts_with_users)
          products_data = fetch_products_data(carts_with_users)
          create_stripe_products_and_prices(products_data)
          create_invoice_items(carts_with_users)
          create_invoices(carts_with_users)
        rescue StandardError => e
          @logger.error("Failed to execute script: #{e.message}")
          raise
        end
      end

      private

      # Configure Stripe API client
      def configure_stripe
        ::Stripe.api_key = Settings.stripe.api_key
        @logger.info("Configured Stripe with API key")
      rescue StandardError => e
        @logger.error("Failed to configure Stripe: #{e.message}")
        raise
      end

      # Configure FakeStore API client
      def configure_fakestore_client
        @client = Faraday.new(
          url: 'https://fakestoreapi.com',
          headers: { 'Content-Type' => 'application/json' }
        ) do |f|
          f.response :json
        end
      end

      # Fetch carts and merge with user data
      def fetch_carts_with_users
        @logger.info("Fetching carts from FakeStore API")
        response = @client.get('/carts')
        carts = response.body

        carts.map do |cart|
          user_data = fetch_user_data(cart['id'])
          cart.merge('user_data' => user_data)
        end
      end

      # Fetch user data for a specific cart
      def fetch_user_data(user_id)
        response = @client.get("/users/#{user_id}")
        response.body
      end

      # Create Stripe customers from cart data
      def create_customers(carts)
        @logger.info("Creating Stripe customers")
        carts.each do |cart|
          create_customer(cart)
        end
      end

      # Create individual Stripe customer
      def create_customer(cart)
        user_data = cart['user_data']
        customer_name = "#{user_data['name']['firstname']} #{user_data['name']['lastname']}".titleize

        ::Stripe::Customer.create(
          name: customer_name,
          email: user_data['email'],
          metadata: {
            fakestore_id: cart['id'].to_s
          }
        )
      rescue ::Stripe::StripeError => e
        @logger.error("Failed to create customer: #{e.message}")
        raise
      end

      # Fetch product data for all products in carts
      def fetch_products_data(carts)
        @logger.info("Fetching product data")
        product_ids = carts.flat_map { |cart| cart['products'].map { |p| p['productId'] } }.uniq
        product_ids.each_with_object({}) do |product_id, products|
          response = @client.get("/products/#{product_id}")
          products[product_id] = response.body
        end
      end

      # Create Stripe products and their prices
      def create_stripe_products_and_prices(products_data)
        @logger.info("Creating Stripe products and prices")
        products_data.values.each do |product|
          stripe_product = create_stripe_product(product)
          create_stripe_price(product, stripe_product.id)
        end
      end

      # Create individual Stripe product
      def create_stripe_product(product)
        ::Stripe::Product.create(
          name: product['title'],
          description: product['description'],
          metadata: {
            fakestore_id: product['id'].to_s
          }
        )
      rescue ::Stripe::StripeError => e
        @logger.error("Failed to create product: #{e.message}")
        raise
      end

      # Create price for Stripe product
      def create_stripe_price(product, stripe_product_id)
        ::Stripe::Price.create(
          currency: 'usd',
          product: stripe_product_id,
          unit_amount: (product['price'] * 100).to_i,
          metadata: {
            fakestore_id: product['id'].to_s
          }
        )
      rescue ::Stripe::StripeError => e
        @logger.error("Failed to create price: #{e.message}")
        raise
      end

      # Create invoice items for all carts
      def create_invoice_items(carts)
        @logger.info("Creating invoice items")
        carts.each do |cart|
          create_cart_invoice_items(cart)
        end
      end

      # Create invoice items for a specific cart
      def create_cart_invoice_items(cart)
        customer = find_customer_by_fakestore_id(cart['id'])

        cart['products'].each do |product|
          price = find_price_by_fakestore_id(product['productId'])

          ::Stripe::InvoiceItem.create(
            customer: customer.id,
            price: price.id,
            quantity: product['quantity'],
            metadata: {
              fakestore_product_id: product['productId'].to_s
            }
          )
        end
      rescue ::Stripe::StripeError => e
        @logger.error("Failed to create invoice items: #{e.message}")
        raise
      end

      # Create draft invoices for all carts
      def create_invoices(carts)
        @logger.info("Creating draft invoices")
        carts.each do |cart|
          create_draft_invoice(cart)
        end
      end

      # Create draft invoice for a specific cart
      def create_draft_invoice(cart)
        customer = find_customer_by_fakestore_id(cart['id'])

        ::Stripe::Invoice.create(
          customer: customer.id,
          auto_advance: false,
          metadata: {
            fakestore_cart_id: cart['id'].to_s
          }
        )
      rescue ::Stripe::StripeError => e
        @logger.error("Failed to create invoice: #{e.message}")
        raise
      end

      # Helper method to find Stripe customer by FakeStore ID
      def find_customer_by_fakestore_id(fakestore_id)
        ::Stripe::Customer.search(
          query: "metadata['fakestore_id']:\'#{fakestore_id}\'"
        ).first
      end

      # Helper method to find Stripe price by FakeStore product ID
      def find_price_by_fakestore_id(fakestore_id)
        ::Stripe::Price.search(
          query: "metadata['fakestore_id']:\'#{fakestore_id}\'"
        ).first
      end
    end
  end
end