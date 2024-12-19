# frozen_string_literal: true

RSpec.describe Scripts::Stripe::CreateInvoiceStripeScript do
  let(:script) { described_class.new }
  let(:do_call) { script.call }

  context 'with Stripe token' do
    it 'calls script normally' do
      VCR.use_cassette '_create_invoice_stripe_script' do
        expect { do_call }.not_to raise_error
      end
    end
  end
end
