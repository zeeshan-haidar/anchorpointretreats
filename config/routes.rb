Rails.application.routes.draw do
  # Public pages
  # GET /
  root 'pages#home'

  # GET /the-retreat
  get 'the-retreat', to: 'pages#retreat'

  # GET /experience
  get 'experience', to: 'pages#experience'

  # GET /about
  get 'about', to: 'pages#about'

  # GET /faq
  get 'faq', to: 'pages#faq'

  # GET /policies
  get 'policies', to: 'pages#policies'

  # GET /privacy
  get 'privacy', to: 'pages#privacy'

  # GET /terms
  get 'terms', to: 'pages#terms'

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
