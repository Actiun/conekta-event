ConektaEvent::Engine.routes.draw do
  post '/', to: 'webhook#event'
end
