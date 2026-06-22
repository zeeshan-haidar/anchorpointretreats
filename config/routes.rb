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

  # Devise for AdminUser (scoped to /admin)
  devise_for :admin_users, controllers: { sessions: "admin/sessions" }, path: "admin", path_names: {
    sign_in: "login", sign_out: "logout", password: "password"
  }

  # Stripe webhook
  post "webhooks/stripe", to: "webhooks#stripe"

  # ──────────────────────────────────────────────
  # Admin Panel
  # ──────────────────────────────────────────────
  namespace :admin do
    # Dashboard
    get "/", to: "dashboard#index", as: :root

    # Calendar management
    resources :calendar, only: [:index] do
      collection do
        post :bulk_update
      end
      member do
        patch :update
      end
    end

    # Bookings
    resources :bookings do
      member do
        post :refund
      end
      collection do
        get :export, defaults: { format: :csv }
      end
    end

    # Inquiries
    resources :inquiries, only: [:index, :show, :update]

    # Property management
    resource :property, only: [:edit, :update], controller: "property"

    # Photos (nested under property)
    resources :photos, controller: "photos", as: :property_photos do
      collection do
        post :reorder
      end
    end

    # Amenities (nested under property)
    resources :amenities, controller: "amenities", as: :property_amenities

    # Seasonal pricing
    resources :seasonal_pricings, controller: "seasonal_pricings", as: :property_seasonal_pricings

    # Testimonials
    resources :testimonials

    # Site content
    resources :content, only: [:index, :update], controller: "content"

    # Settings
    resource :settings, only: [:edit, :update], controller: "settings"
  end
end
