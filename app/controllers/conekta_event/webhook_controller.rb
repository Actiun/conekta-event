module ConektaEvent
  class WebhookController < ActionController::Base
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
  end
end
