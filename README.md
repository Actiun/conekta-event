# ConektaEvent
ConketaEvent is built on the [ActiveSupport::Notifications API](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html). Incoming webhook requests are authenticated by [retrieving the event object](https://developers.conekta.com/api#events) from Conketa. Define subscribers to handle specific event types. Subscribers can be a block or an object that responds to `#call`.

This gem is based on [StripeEvent](https://github.com/integrallis/stripe_event) by [Ryan McGeary](https://github.com/rmm5t) , [Pete Keen](https://github.com/peterkeen) and [Danny Whalen](https://github.com/invisiblefunnel) . ConektaEvent improves on the gem, updating for Rails 4,  using [Conekta](https://www.conekta.com/en)  as Payment Gateway.

## Install

```ruby
# Gemfile
gem 'conekta_event'
```

```ruby
# config/routes.rb
mount Conekta::Engine, at: '/my-chosen-path' # provide a custom path
```

## Usage

```ruby
# config/initializers/conekta.rb
Conekta.api_key = ENV['CONKECTA_SECRET_KEY'] # e.g. key_eYvWV7gSDkNYXsmr

ConektaEvent.configure do |events|
  events.subscribe 'charge.paid' do |event|
    # Define subscriber behavior based on the event object
    event.class       #=> Conekta::Event
    event.type        #=> "charge.paid"
    event.data['object'] #=> {"id"=>"55b2b487241229ca9c000026", ... }
  end

  events.all do |event|
    # Handle all event types - logging, etc.
  end
end
```

### Subscriber objects that respond to #call

```ruby
class CustomerCreated
  def call(event)
    # Event handling
  end
end

class BillingEventLogger
  def initialize(logger)
    @logger = logger
  end

  def call(event)
    @logger.info "BILLING:#{event.type}:#{event.id}"
  end
end
```

```ruby
ConektaEvent.configure do |events|
  events.all BillingEventLogger.new(Rails.logger)
  events.subscribe 'customer.created', CustomerCreated.new
end
```

### Subscribing to a namespace of event types

```ruby
ConektaEvent.subscribe 'customer.card.' do |event|
  # Will be triggered for any customer.card.* events
end
```

## Securing your webhook endpoint

ConektaEvent automatically fetches events from Conekta to ensure they haven't been forged. However, that doesn't prevent an attacker who knows your endpoint name and an event's ID from forcing your server to process a legitimate event twice. If that event triggers some useful action, like generating a license key or enabling a delinquent account, you could end up giving something the attacker is supposed to pay for away for free.

To prevent this, ConektEvent supports verification by signature on your webhook endpoint, this helps us to validate that data were not sent by a third-party.  Here's what you do for use this feature:

1.  First need to retrieve your endpoint’s secret in your Conekta Dashboard so Conekta start to sign each webhook sent to the endpoint.
2. Arrange for a secret key to be available in your application's environment variables or `secrets.yml` file. You can generate a suitable secret with the `rake secret` command. (Remember, the `secrets.yml` file shouldn't contain production secrets directly; it should use ERB to include them.)

3. Configure ConektaEvent to require that secret be used as a basic authentication password, using code along the lines of these examples:

    ```ruby
    # CONEKTA_PRIVATE_SIGNATURE environment variable
    ConektaEvent.private_signature = ENV['CONEKTA_PRIVATE_SIGNATURE']
    # stripe_webhook_secret key in secrets.yml file
    ConektaEvent.private_signature = Rails.application.secrets.conekta_private_signature
    ```

4. You are done!

Remember to add an extra layer of protection and secure your webhook endpoint with SSL.

## Configuration

If you'd like to ignore particular webhook events (perhaps to ignore test webhooks in production, or to ignore webhooks for a non-paying customer), you can do so by returning `nil` in you custom `event_retriever`. For example:

```ruby
ConektaEvent.event_retriever = lambda do |params|
  return nil if Rails.env.production? && !params[:livemode]
  Conekta::Event.retrieve(params[:id])
end
```

```ruby
ConektaEvent.event_retriever = lambda do |params|
  account = Account.find_by!(conekta_user_id: params[:user_id])
  return nil if account.delinquent?
  Conekta::Event.find(params[:id], account.api_key)
end
```

## Testing

Handling webhooks is a critical piece of modern billing systems. Verifying the behavior of ConektaEvent subscribers can be done fairly easily by stubbing out the HTTP request used to authenticate the webhook request. Tools like [Webmock](https://github.com/bblimke/webmock) and [VCR](https://github.com/vcr/vcr) work well. [RequestBin](http://requestb.in/) is great for collecting the payloads. For exploratory phases of development, [UltraHook](http://www.ultrahook.com/) and other tools can forward webhook requests directly to localhost. An example:

```ruby
# spec/requests/billing_events_spec.rb
require 'spec_helper'

describe "Billing Events" do
  def stub_event(fixture_id, status = 200)
    stub_request(:get, "https://api.conekta.io/events/#{fixture_id}").
      to_return(status: status, body: File.read("spec/support/fixtures/#{fixture_id}.json"))
  end

  describe "customer.created" do
    before do
      stub_event 'evt_customer_created'
    end

    it "is successful" do
      post '/_billing_events', id: 'evt_customer_created'
      expect(response.code).to eq "200"
      # Additional expectations...
    end
  end
end
```

### Note: 'Test Webhooks' Button on Conekta Dashboard

This button sends an example event to your webhook urls, including a random `id`. To confirm that Conekta sent the webhook, ConektaEvent attempts to retrieve the event details from Conekta using the given `id`. In this case the event does not exist and Conekta Event responds with `401 Unauthorized`. Instead of using the 'Test Webhooks' button, trigger webhooks by using the Conekta API or if you already have some events in your test account you can send them manually  to create test payments, customers, etc.

### Maintainers

* [Jorge Najera](https://github.com/jNajera)

### Versioning

Semantic Versioning 2.0 as defined at <http://semver.org>.

### License

[MIT License](https://github.com/Actiun/conkecta-event/blob/master/MIT-LICENSE).
