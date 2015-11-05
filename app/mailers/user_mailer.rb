class UserMailer < ApplicationMailer
  default from: 'Appfolio Ladle <no-reply@appfolio.com>'

  def notify(email:, pull_request_url:, stewards_files:)
    @url = pull_request_url
    @stewards_files = stewards_files
    mail(to: email, subject: 'Ladle: New PR')
  end
end
