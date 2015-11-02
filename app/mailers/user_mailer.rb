class UserMailer < ApplicationMailer
  default from: 'xanderstrike@gmail.com'

  def notify(email, github_url)
    @url = github_url
    mail(to: email, subject: 'Ladle: New PR')
  end
end
