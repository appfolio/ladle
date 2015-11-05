class UserMailer < ApplicationMailer
  default from: 'Appfolio Ladle <no-reply@appfolio.com>'

  def notify(user:, repository:, pull_request:, stewards_files:)
    pull_request.assert_valid_keys(:number, :url, :description, :title)
    raise ArgumentError, "pull_request[:url] required" if pull_request[:url].blank?

    pull_request = pull_request.dup
    pull_request[:title] ||= "New Pull Request"

    @pull_request   = pull_request
    @stewards_files = stewards_files
    @user = user

    mail(to:      user.email,
         subject: "[#{repository}] Ladle Alert: #{pull_request[:title]}")
  end
end
