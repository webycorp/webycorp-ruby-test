# frozen_string_literal: true

RSpec.describe Scripts::Stripe::CreateInvoiceStripeScript do
   let(:script) { described_class.new }
   let(:do_call) { script.call }

   context 'with Stripe token' do
     it 'calls script normally', vcr: { cassette_name: 'create_invoice_stripe_script' } do
       expect { do_call }.not_to raise_error
     end
   end

   context 'without Stripe token' do
  
     before do
       allow(Settings).to receive(:stripe).and_return(double('StripeDouble', api_key: 'test_key'))
     end

     it 'calls script with Stripe broken', vcr: { cassette_name: 'create_invoice_stripe_script' } do
       expect { do_call }.to raise_error Stripe::AuthenticationError
     end
   end

   context 'FakestoreApiService side errors' do

     it 'checks init logger', vcr: { cassette_name: 'create_invoice_stripe_script' } do
       expect script.instance_variables.include? :@logger
     end

     it 'checks init fakestore_client', vcr: { cassette_name: 'create_invoice_stripe_script' } do
       expect script.instance_variables.include? :@fakestore_client
     end

   end

end


























# old version with stubs
# RSpec.describe Scripts::Stripe::CreateInvoiceStripeScript do
#   let(:script) { described_class.new }
#   let(:fake_client) { instance_double(FakestoreApiService::Client) }
#   let(:stripe_customer) { double('Stripe::Customer', id: 'cus_123') }
#   let(:stripe_product) { double('Stripe::Product', id: 'prod_123') }
#   let(:stripe_price) { double('Stripe::Price', id: 'price_123') }
#   let(:stripe_invoice) { double('Stripe::Invoice', id: 'inv_123') }
#   let(:stripe_invoice_item) { double('Stripe::InvoiceItem', customer: stripe_customer, limit: 100, price: stripe_price, quantity: 1) }
#   let(:cart) do
#     {
#       'id' => 1,
#       'products' => [{ 'productId' => 1, 'quantity' => 2 }],
#       'user_data' => { 'name' => { 'firstname' => 'John', 'lastname' => 'Doe' }, 'email' => 'john.doe@example.com' }
#     }
#   end
#   let(:product) { { 'id' => 1, 'title' => 'Test Product', 'description' => 'A test product.', 'price' => 10.0 } }
#
#   before do
#     allow(FakestoreApiService::Client).to receive(:new).and_return(fake_client)
#     allow(fake_client).to receive(:request_get_carts).and_return(double(body: [cart]))
#     allow(fake_client).to receive(:request_get_user).with(1).and_return(double(body: cart['user_data']))
#     allow(fake_client).to receive(:request_get_product).with(1).and_return(double(body: product))
#
#     allow(Stripe::Product).to receive(:create).and_return(stripe_product)
#     allow(Stripe::Price).to receive(:create).and_return(stripe_price)
#     allow(Stripe::Invoice).to receive(:create).and_return(stripe_invoice)
#     allow(Stripe::Invoice).to receive(:finalize_invoice).with('inv_123')
#
#     allow(Stripe::InvoiceItem).to receive(:create)
#     allow(Stripe::InvoiceItem).to receive(:list).and_return(double('ListResult', data: [stripe_invoice_item]))
#
#     allow(Stripe::Customer).to receive(:search).and_return(double('SearchResult', first: stripe_customer))
#     allow(Stripe::Price).to receive(:search).and_return(double('SearchResult', first: stripe_price))
#     allow(Stripe::Customer).to receive(:create).and_return(stripe_customer)
#     allow(Stripe::Customer).to receive(:retrieve).with('cus_123').and_return(stripe_customer)
#     allow(Stripe::Product).to receive(:create).and_return(stripe_product)
#     allow(Stripe::Price).to receive(:create).and_return(stripe_price)
#     allow(Stripe::Invoice).to receive(:create).and_return(stripe_invoice)
#     allow(Stripe::InvoiceItem).to receive(:create)
#   end
#
#   describe '#call' do
#     it 'processes carts and creates invoices without errors', vcr: { cassette_name: 'stripe_create_invoice_success' } do
#       expect { script.call }.not_to raise_error
#     end
#   end
# end
