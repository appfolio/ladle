require 'ladle/notify_stewards_of_pull_request_changes'

class GithubEventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :find_repository, only: [:payload]
  before_filter :verify_signature, only: [:payload]

  def payload
    number              = params.require(:number)
    pull_request_params = params.require(:pull_request)
    pull_request_state  = pull_request_params.require(:state)

    Rails.logger.info "New pull ##{number} for #{@repository.name}. Running handler..."

    if pull_request_state == 'open'
      pull_request = find_pull_request(number:   number,
                                       html_url: pull_request_params[:html_url],
                                       title:    pull_request_params[:title],
                                       body:     pull_request_params[:body])

      Ladle::NotifyStewardsOfPullRequestChanges.(pull_request)
    else
      Rails.logger.info 'Pull closed, doing nothing.'
    end

    render status: :ok, nothing: true
  end

  private

  def find_pull_request(number:, html_url:, title:, body:)
    ActiveRecord::Base.transaction do
      pull_request = PullRequest.find_or_create_by!(repository: @repository, number: number, html_url: html_url)
      pull_request.update_attributes!(
        title: title,
        body:  body
      )
      pull_request
    end
  end

  def find_repository
    repository = params.require(:repository)

    @repository = Repository.find_by_name(repository[:full_name])
    unless @repository
      render status: :forbidden, nothing: true
    end
  end

  def verify_signature
    request.body.rewind
    payload_body = request.body.read

    signature = @repository.compute_webhook_signature(payload_body)

    unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'] || '')
      Rails.logger.info "Signature mismatch - recv: <#{request.env['HTTP_X_HUB_SIGNATURE'].inspect}> calc <#{signature.inspect}>"
      render status: :forbidden, nothing: true
    end
  end
end
