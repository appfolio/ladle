require 'pull_handler'

class GithubEventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  before_filter :find_repository, only: [:payload]
  before_filter :verify_signature, only: [:payload]

  def payload
    pull_request = params.require(:pull_request)

    if pull_request[:state] == 'open'
      number = params.require(:number)
      Rails.logger.info "New pull ##{number} for #{@repository.name}. Running handler..."

      pull_request_data = {
        number:      number,
        html_url:    pull_request[:html_url],
        title:       pull_request[:title],
        description: pull_request[:description],
      }
      PullHandler.new(repository:        @repository,
                      pull_request_data: pull_request_data).handle
    else
      Rails.logger.info 'Pull closed, doing nothing.'
    end

    render status: :ok, nothing: true
  end

  private

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
