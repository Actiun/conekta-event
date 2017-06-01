ConektaEvent::Engine.routes.draw do
  # root to: 'webhook#event', via: :post
  post '/', to: 'webhook#event'
end
