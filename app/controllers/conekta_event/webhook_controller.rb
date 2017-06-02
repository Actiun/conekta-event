module ConektaEvent
  class WebhookController < ActionController::Base
    if respond_to?(:before_action)
      before_action :request_authentication
    else
      before_filter :request_authentication
    end

    def event
      ConektaEvent.instrument(params)
      head :ok
    rescue ConektaEvent::UnauthorizedError => e
      log_error(e)
      head :unauthorized
    end

    private

    def log_error(e)
      logger.error e.message
      e.backtrace.each { |line| logger.error "  #{line}" }
    end

    def request_authentication
      if ConektaEvent.private_signature
        digest = request.env['HTTP_DIGEST']
        if digest.blank?
          logger.error "Conekta Error => No Digest"
          head :unauthorized
          return
        end
        begin
          private_key = OpenSSL::PKey::RSA.new(ConektaEvent.private_signature)
          sha256_message = private_key.private_decrypt(Base64.decode64(digest))
          if sha256_message != Digest::SHA256.hexdigest(request.raw_post)
            logger.error "Conekta Error => Unauthenticated Event"
            head :unauthorized
          end
        rescue OpenSSL::PKey::RSAError => e
          log_error(e)
          head :unauthorized
        end
      end
    end
  end
end
