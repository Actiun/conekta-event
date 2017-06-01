require 'rails_helper'

describe ConektaEvent do
  let(:events) { [] }
  let(:subscriber) { ->(evt){ events << evt } }
  let(:charge_succeeded) { double('charge paid') }
  let(:subscription_canceled) { double('subscription canceled') }

  describe ".configure" do
    it "yields itself to the block" do
      yielded = nil
      ConektaEvent.configure { |events| yielded = events }
      expect(yielded).to eq ConektaEvent
    end

    it "requires a block argument" do
      expect { ConektaEvent.configure }.to raise_error ArgumentError
    end

    describe ".setup - deprecated" do
      it "evaluates the block in its own context" do
        ctx = nil
        ConektaEvent.setup { ctx = self }
        expect(ctx).to eq ConektaEvent
      end
    end
  end

  describe "subscribing to a specific event type" do
    before do
      expect(charge_succeeded).to receive(:[]).with(:type).and_return('charge.paid')
      expect(Conekta::Event).to receive(:find).with('evt_charge_paid').and_return(charge_succeeded)
    end

    context "with a block subscriber" do
      it "calls the subscriber with the retrieved event" do
        ConektaEvent.subscribe('charge.paid', &subscriber)

        ConektaEvent.instrument(id: 'evt_charge_paid', type: 'charge.paid')

        expect(events).to eq [charge_succeeded]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with the retrieved event" do
        ConektaEvent.subscribe('charge.paid', subscriber)

        ConektaEvent.instrument(id: 'evt_charge_paid', type: 'charge.paid')

        expect(events).to eq [charge_succeeded]
      end
    end
  end

  describe "subscribing to the 'account.application.deauthorized' event type" do
    before do
      expect(Conekta::Event).to receive(:find).with('evt_account_application_deauthorized').and_raise(Conekta::ErrorList)
    end

    context "with a subscriber params with symbolized keys" do
      it "calls the subscriber with the retrieved event" do
        ConektaEvent.subscribe('account.application.deauthorized', subscriber)

        ConektaEvent.instrument(id: 'evt_account_application_deauthorized', type: 'account.application.deauthorized')

        expect(events.first.type).to    eq 'account.application.deauthorized'
        expect(events.first[:type]).to  eq 'account.application.deauthorized'
      end
    end

    context "with a subscriber params with indifferent access (stringified keys)" do
      it "calls the subscriber with the retrieved event" do
        ConektaEvent.subscribe('account.application.deauthorized', subscriber)

        ConektaEvent.instrument({ id: 'evt_account_application_deauthorized', type: 'account.application.deauthorized' }.with_indifferent_access)

        expect(events.first.type).to    eq 'account.application.deauthorized'
        expect(events.first[:type]).to  eq 'account.application.deauthorized'
      end
    end
  end

  # describe "subscribing to a namespace of event types" do
  #   let(:card_created) { double('card created') }
  #   let(:card_updated) { double('card updated') }
  #
  #   before do
  #     expect(card_created).to receive(:[]).with(:type).and_return('customer.card.created')
  #     expect(Stripe::Event).to receive(:retrieve).with('evt_card_created').and_return(card_created)
  #
  #     expect(card_updated).to receive(:[]).with(:type).and_return('customer.card.updated')
  #     expect(Stripe::Event).to receive(:retrieve).with('evt_card_updated').and_return(card_updated)
  #   end
  #
  #   context "with a block subscriber" do
  #     it "calls the subscriber with any events in the namespace" do
  #       ConektaEvent.subscribe('customer.card', &subscriber)
  #
  #       ConektaEvent.instrument(id: 'evt_card_created', type: 'customer.card.created')
  #       ConektaEvent.instrument(id: 'evt_card_updated', type: 'customer.card.updated')
  #
  #       expect(events).to eq [card_created, card_updated]
  #     end
  #   end
  #
  #   context "with a subscriber that responds to #call" do
  #     it "calls the subscriber with any events in the namespace" do
  #       ConektaEvent.subscribe('customer.card.', subscriber)
  #
  #       ConektaEvent.instrument(id: 'evt_card_updated', type: 'customer.card.updated')
  #       ConektaEvent.instrument(id: 'evt_card_created', type: 'customer.card.created')
  #
  #       expect(events).to eq [card_updated, card_created]
  #     end
  #   end
  # end

  describe "subscribing to all event types" do
    before do
      expect(charge_succeeded).to receive(:[]).with(:type).and_return('charge.paid')
      expect(Conekta::Event).to receive(:find).with('evt_charge_paid').and_return(charge_succeeded)

      expect(subscription_canceled).to receive(:[]).with(:type).and_return('subscription.canceled ')
      expect(Conekta::Event).to receive(:find).with('evt_subscription_canceled').and_return(subscription_canceled)
    end

    context "with a block subscriber" do
      it "calls the subscriber with all retrieved events" do
        ConektaEvent.all(&subscriber)

        ConektaEvent.instrument(id: 'evt_charge_paid', type: 'charge.succeeded')
        ConektaEvent.instrument(id: 'evt_subscription_canceled', type: 'subscription.canceled ')

        expect(events).to eq [charge_succeeded, subscription_canceled]
      end
    end

    context "with a subscriber that responds to #call" do
      it "calls the subscriber with all retrieved events" do
        ConektaEvent.all(subscriber)

        ConektaEvent.instrument(id: 'evt_charge_paid', type: 'charge.succeeded')
        ConektaEvent.instrument(id: 'evt_subscription_canceled', type: 'subscription.canceled ')

        expect(events).to eq [charge_succeeded, subscription_canceled]
      end
    end
  end

  describe ".listening?" do
    it "returns true when there is a subscriber for a matching event type" do
      ConektaEvent.subscribe('customer.', &subscriber)

      expect(ConektaEvent.listening?('customer.card')).to be true
      expect(ConektaEvent.listening?('customer.')).to be true
    end

    it "returns false when there is not a subscriber for a matching event type" do
      ConektaEvent.subscribe('customer.', &subscriber)

      expect(ConektaEvent.listening?('account')).to be false
    end

    it "returns true when a subscriber is subscribed to all events" do
      ConektaEvent.all(&subscriber)

      expect(ConektaEvent.listening?('customer.')).to be true
      expect(ConektaEvent.listening?('account')).to be true
    end
  end

  describe ConektaEvent::NotificationAdapter do
    let(:adapter) { ConektaEvent.adapter }

    it "calls the subscriber with the last argument" do
      expect(subscriber).to receive(:call).with(:last)

      adapter.call(subscriber).call(:first, :last)
    end
  end

  describe ConektaEvent::Namespace do
    let(:namespace) { ConektaEvent.namespace }

    describe "#call" do
      it "prepends the namespace to a given string" do
        expect(namespace.call('foo.bar')).to eq 'conekta_event.foo.bar'
      end

      it "returns the namespace given no arguments" do
        expect(namespace.call).to eq 'conekta_event.'
      end
    end

    describe "#to_regexp" do
      it "matches namespaced strings" do
        expect(namespace.to_regexp('foo.bar')).to match namespace.call('foo.bar')
      end

      it "matches all namespaced strings given no arguments" do
        expect(namespace.to_regexp).to match namespace.call('foo.bar')
      end
    end
  end
end
