class ApplicationMailer < ActionMailer::Base
  default from: "The Anchorpoint Retreat <hello@anchorpointretreat.com>",
          bcc: "anchorpointusa@gmail.com"
  layout 'mailer'
end
