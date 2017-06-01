require 'rails_helper'

describe ConektaEvent::WebhookController, type: :controller do
  routes { ConektaEvent::Engine.routes }

  def stub_event(identifier, status = 200)
    stub_request(:get, "https://api.conekta.io/events/#{identifier}").
      to_return(status: status, body: File.read("spec/support/fixtures/#{identifier}.json"))
  end

  def webhook(params = {})
    post :event, params: params
  end

  it "succeeds with valid event data" do
    count = 0
    ConektaEvent.subscribe('charge.paid') { |evt| count += 1 }
    stub_event('evt_charge_paid')

    webhook id: 'evt_charge_paid'

    expect(response.code).to eq '200'
    expect(count ==  1)
  end

  it "succeeds when the event_retriever returns nil (simulating an ignored webhook event)" do
    count = 0
    ConektaEvent.event_retriever = lambda { |params| return nil }
    ConektaEvent.subscribe('charge.paid') { |evt| count += 1 }
    stub_event('evt_charge_paid')

    webhook id: 'evt_charge_paid'

    expect(response.code).to eq '200'
    expect(count ==  0)
  end

  it "denies access with invalid event data" do
    count = 0
    ConektaEvent.subscribe('charge.paid') { |evt| count += 1 }
    stub_event('evt_invalid_id', 404)

    webhook id: 'evt_invalid_id'

    expect(response.code).to eq '401'
    expect(count ==  0)
  end
end
