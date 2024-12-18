# frozen_string_literal: true

RSpec.describe FakestoreApiService::Client do
  let(:logger) { Logger.new($stdout) }
  let(:client) { described_class.new(logger) }

  describe '#request_get_carts' do
    it 'fetches carts successfully', vcr: { cassette_name: 'fakestore_get_carts' } do
      response = client.request_get_carts
      expect(response.body).not_to be_empty
    end
  end

  describe '#request_get_user' do
    it 'fetches a user successfully', vcr: { cassette_name: 'fakestore_get_user' } do
      response = client.request_get_user(1)
      expect(response.body).to include('name')
    end
  end

  describe '#request_get_product' do
    it 'fetches a product successfully', vcr: { cassette_name: 'fakestore_get_product' } do
      response = client.request_get_product(1)
      expect(response.body).to include('title')
    end
  end
end
