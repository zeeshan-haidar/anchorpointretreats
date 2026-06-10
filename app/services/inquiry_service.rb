# app/services/inquiry_service.rb
require "ostruct"
# Creates an inquiry record with rate limiting support.
class InquiryService
  MAX_PER_IP_PER_HOUR = 5

  def initialize(property = nil)
    @property = property
  end

  # Creates an inquiry record
  # params: { name, email, phone, company, retreat_type, preferred_dates, group_size, message }
  # options: { ip_address: } for rate limiting
  def call(params, ip_address: nil)
    # Rate limiting: check if IP has exceeded the limit
    if ip_address.present? && rate_limited?(ip_address)
      return OpenStruct.new(
        success?: false,
        error: "Too many inquiries from this IP address. Please try again later.",
        rate_limited: true
      )
    end

    inquiry = Inquiry.new(
      name: params[:name],
      email: params[:email],
      phone: params[:phone],
      company: params[:company],
      retreat_type: params[:retreat_type],
      preferred_dates: params[:preferred_dates],
      group_size: params[:group_size].present? ? params[:group_size].to_i : nil,
      message: params[:message],
      status: :new_inquiry
    )

    if inquiry.save
      # Send email notifications
      InquiryMailer.received(inquiry).deliver_later
      admin_email = AdminUser.first&.email || "dbmanager81@gmail.com"
      InquiryMailer.new_inquiry_alert(inquiry, admin_email).deliver_later

      OpenStruct.new(success?: true, inquiry: inquiry)
    else
      OpenStruct.new(
        success?: false,
        error: inquiry.errors.full_messages.join(", "),
        inquiry: inquiry
      )
    end
  end

  private

  def rate_limited?(ip_address)
    recent_count = Inquiry.where("created_at > ?", 1.hour.ago)
                          .where("created_at < ?", Time.current)
                          .count

    # Simple in-memory rate limiting using a cache key
    # In production, use Rack::Attack with Redis for this
    recent_from_ip = Rails.cache.fetch("inquiry_ip:#{ip_address}") { 0 }
    recent_from_ip >= MAX_PER_IP_PER_HOUR
  end
end
