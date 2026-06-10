# frozen_string_literal: true

# Sends transactional emails related to inquiries.
#   received        — thank-you email to the guest after submitting an inquiry
#   new_inquiry     — notification to the admin when a new inquiry comes in
class InquiryMailer < ApplicationMailer
  # Email: Inquiry Received (guest-facing)
  # Sent after the guest submits an inquiry form.
  def received(inquiry)
    @inquiry = inquiry

    mail(
      to: inquiry.email,
      subject: "Thank You for Your Inquiry — The Anchorpoint Retreat"
    )
  end

  # Email: New Inquiry Alert (admin-facing)
  # Sent to the property admin/owner when a new inquiry is submitted.
  def new_inquiry_alert(inquiry, admin_email)
    @inquiry = inquiry

    mail(
      to: admin_email,
      subject: "New Inquiry from #{inquiry.name} — The Anchorpoint Retreat"
    )
  end
end
