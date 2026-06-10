Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Public pages
  root "pages#home"
  get "the-retreat", to: "pages#retreat"
  get "experience", to: "pages#experience"
  get "about", to: "pages#about"
  get "faq", to: "pages#faq"
  get "policies", to: "pages#policies"
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Availability & Pricing
  get "availability", to: "availability#index"
  get "availability/calendar", to: "availability#calendar"
  get "availability/pricing", to: "availability#pricing"

  # Bookings
  get "book", to: "bookings#new"
  post "book", to: "bookings#create"
  get "book/:id/payment", to: "bookings#payment", as: :booking_payment
  post "book/:id/checkout", to: "bookings#checkout", as: :booking_checkout
  get "book/:id/confirmation", to: "bookings#confirmation", as: :booking_confirmation

  # Inquiries
  get "inquiry", to: "inquiries#new"
  post "inquiry", to: "inquiries#create"
  get "inquiry/thank-you", to: "inquiries#thank_you", as: :inquiry_thank_you

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Stripe webhook
  post "webhooks/stripe", to: "webhooks#stripe"
end
