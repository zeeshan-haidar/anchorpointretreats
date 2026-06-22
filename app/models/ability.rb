# app/models/ability.rb
# CanCanCan ability definitions for admin users

class Ability
  include CanCan::Ability

  def initialize(admin_user)
    admin_user ||= AdminUser.new(role: :admin)

    if admin_user.super_admin?
      can :manage, :all
    else
      # Admin users can manage most resources
      can :manage, Booking
      can :manage, Inquiry
      can :manage, Testimonial
      can :manage, SiteContent
      can :manage, Availability
      can :manage, Amenity
      can :manage, SeasonalPricing
      can :manage, PropertyImage
      can :read, Property
      can :update, Property

      # Cannot manage other admin users
      cannot :manage, AdminUser

      # Cannot manage settings
      cannot :manage, :settings
    end
  end
end
