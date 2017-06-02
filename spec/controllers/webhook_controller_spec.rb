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

  context "with an authentication" do
    def webhook_with_digest(digest, params)
      request.env['HTTP_DIGEST'] = digest
      request.env['RAW_POST_DATA'] = "{\"data\":{\"object\":{\"url\":\"http://f4888b71.ngrok.io/conekta/webooks\",\"status\":\"error\",\"production_enabled\":false,\"development_enabled\":true,\"subscribed_events\":[\"charge.created\",\"charge.paid\",\"charge.under_fraud_review\",\"charge.fraudulent\",\"charge.refunded\",\"charge.preauthorized\",\"charge.expired\",\"charge.declined\",\"charge.expired\",\"customer.created\",\"customer.updated\",\"customer.deleted\",\"webhook.created\",\"webhook.updated\",\"webhook.deleted\",\"charge.chargeback.created\",\"charge.chargeback.updated\",\"charge.chargeback.under_review\",\"charge.chargeback.lost\",\"charge.chargeback.won\",\"payout.created\",\"payout.retrying\",\"payout.paid_out\",\"payout.failed\",\"plan.created\",\"plan.updated\",\"plan.deleted\",\"subscription.created\",\"subscription.paused\",\"subscription.resumed\",\"subscription.canceled\",\"subscription.expired\",\"subscription.updated\",\"subscription.paid\",\"subscription.payment_failed\",\"payee.created\",\"payee.updated\",\"payee.deleted\",\"payee.payout_method.created\",\"payee.payout_method.updated\",\"payee.payout_method.deleted\",\"charge.score_updated\",\"order.canceled\",\"order.charged_back\",\"order.created\",\"order.expired\",\"order.fraudulent\",\"order.under_fraud_review\",\"order.paid\",\"order.partially_refunded\",\"order.pending_payment\",\"order.pre_authorized\",\"order.refunded\",\"order.updated\",\"order.voided\"],\"id\":\"592f95deffecf90ad50cbc3b\",\"object\":\"webhook\"},\"previous_attributes\":{}},\"livemode\":false,\"webhook_status\":\"successful\",\"webhook_logs\":[{\"id\":\"webhl_2gd82XRPWokwvFRZU\",\"url\":\"http://f4888b71.ngrok.io/conekta/webooks\",\"failed_attempts\":0,\"last_http_response_status\":-1,\"object\":\"webhook_log\",\"last_attempted_at\":1496412760}],\"id\":\"5931718eb795b0537661ddba\",\"object\":\"event\",\"type\":\"webhook.updated\",\"created_at\":1496412558}"
      webhook params
    end

    before(:each) { ConektaEvent.private_signature = "-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAKCAQEAzuZQvFcZkzlQnC089JyIJLtq7vLEz+MgjsdQO5docuUdPvBP\ncV3wFxWbX4P9MQq6PHAM5EDhy2SAtIW7CrWV44n6zlEYVl5x5peJqee2Pbef9ROA\nrvP3Ja2q4BgxJnGKKoFbYK/FfpGIp+gDSJxy3NJ/KPtHlq88YjJAhja111N054Xl\nQSxeYvvOHl+G8Xg9G1ZU9U0rQfIEwS4WwcMI8OPoFxb26FJi9XlxlmaJ5c1gHSko\noaVczguCYE+JgoYUe6iQjbCheb3XKKav5/rd9grOWBTWwqVS4rALpJjYXERIBWY7\nUHsisKufSZiuTdiJnsYt+UZcFl7F0cma9xMPmwIDAQABAoIBAQC5e47LmgYqj0pu\nCLxJyv7ed0qhVvEMMeFhPtv14IHZ5v62CvgdeQqhl1RIZ+qXibd2MTnNc0E5dytP\nK0iIjEwIxg0b42W/IEJaaGYY9MrTP4heTJKjxcE+fRfgeK+veEBWZMuHvWx/UHdD\nl+NBuEfdIbSwB72hIA4xNj3UVL3mf6THWSOBkG2veUUOLW+WGFh5tn0sBT49cBVh\nTA5uOATnFnC2UsTtDgt2RK1FZv89x+XPHPzd1BDTDQP7jV1X5PUFunxkl/981PIG\njfXl1LsEvgFwa6feOudBOje0wnlzk5onuj/u6adysq/kNs6piQeF7mdmt8odTsMg\nQyoTi8FJAoGBAPP64IYcO1V/DjbE7TpO5/goZ0p3PehmuCaRsxURUu+7DRbe+M9q\np3iPj2pAMPa59eHDDIqhgcW5Nf5iKYGOJTki3XkZhEWJAiNo7+cT8RGpKuKAyVDD\nWoUFHWB4LCyvJvue8FeUwCJwjik8Uf76INSNcxO4EWHUlMRKhxEpUDlHAoGBANkX\nxi6kFwmP0QFpN62kVlVMCOftvxz9NgM3QrZi7xkUQap+RFpbntOQnCmnZo9zfud9\n5OoeIU3bk5K+bU+1T4G4WXIqoECSyQObHQZYL5ARfW8iqDsXun/e4eRZYI+bVRbp\n83h6wv6yn1I/vQpq69HHEJRRRW1D995D5ntTciENAoGAf3bfXFFdklI529VQVvko\nada5+AaKGmOn68aM+AHAAa0Irp05AiwnaG4gMBNvQUdwNU2QvNCaGvGjSs5//saD\nnfEgIgd5ulZU/qjxRRl/BYoK9KDyDDazkPFWIrNF6OZtCGJGEIuPQa7qJpL0B7En\n+8QWjgPJWQIV4uNI42dhGTsCgYEAmkptTeTNgrw1/Vy8d6reuQyrH7s3IvFLnAmA\nXoP+DsL40KWhCt8nCJI0it4w5C9fuEMfmM0FOoKeZaL1qbrg4P8Wgy+MaZhpSSjK\n/iFa3HexwHTPQABjSlIsFdD38diiJwDrS2tkfwSQezJVtru7EoL6Y49HWpr95Xg4\nrNnnuVkCgYEA8CNTLrgPM9GJGrY5xKxnn0LkwH4KTGKE3S9adfjguKDNnXvLQEK3\np+31QtkeYn0945GboUeP1DmCCSS12GqHHmNEFSEVEaV7dD0E25kZp3Jbvuf1shbi\nGjdgwrU7db7k67Mv9UKH7Pe3ZyZD/IGxfyTpMqkXAk8IxpBfX/Msg2k=\n-----END RSA PRIVATE KEY-----\n" }
    after(:each) { ConektaEvent.private_signature = nil }

    it "rejects requests with no secret" do
      stub_event('evt_charge_paid')

      webhook id: 'evt_charge_paid'
      expect(response.code).to eq '401'
    end

    it "rejects requests with incorrect digest" do
      stub_event('evt_charge_paid')

      webhook_with_digest 'abcdef12345', id: 'evt_charge_paid'
      expect(response.code).to eq '401'
    end

    it "accepts requests with correct digest" do
      stub_event('evt_charge_paid')

      webhook_with_digest "wrfDB6Oje19FRkgyhdjmpNq1e+Nlk3AFT+X20R8kImcZ2QI+MOkh6Bfgn/SDDKcAgmkUwZUKiO6xFRM9rGwgpQKeHj8sFKl3f1Gr6+/GEMsZO8h9QOLWfat2P4Tmj0bm6yvxBdXq4PIoRVuz3Pm4bZKz9wgFRQC7Xkj0v3fufJ6w6a+q/9rIV2FEy4SfcrPK5miFd97hmy6THKtLW2QcB5ykIn79JGwQyYP8Ys8S1gY+zhzxV3ZxDJRUabNejuAKA30RL6F3jvzHJZo7xPjaRvIPIaoHAZ5sBpc+N5UYyopa4jPDZZd5iJrEmo5k4SktQQFq8Uw/+0TzhM64n2X6tQ==", id: 'evt_charge_paid'
      expect(response.code).to eq '200'
    end
  end

end
