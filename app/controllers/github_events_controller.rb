require 'pull_handler'

class GithubEventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  class SignatureMismatch < StandardError
  end

  def payload
    request.body.rewind

    payload_body = request.body.read
    verify_signature(payload_body)

    pull_request = params.require(:pull_request)
    repository   = params.require(:repository)

    if pull_request[:state] == 'open'
      repo = repository[:full_name]
      number = params.require(:number)
      Rails.logger.info "New pull ##{number} for #{repo}. Running handler..."
      PullHandler.new(repo: repo,
                      number: number,
                      html_url: pull_request[:html_url]).handle
    else
      Rails.logger.info 'Pull closed, doing nothing.'
    end

    render status: :ok, nothing: true
  rescue SignatureMismatch => e
    Rails.logger.info "#{e} - #{e.message}"
    render status: :forbidden, nothing: true
  end

  private

  def verify_signature(payload_body)
    signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), Rails.application.github_secret_token, payload_body)

    unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'] || '')
      raise SignatureMismatch, "recv: <#{request.env['HTTP_X_HUB_SIGNATURE'].inspect}> calc <#{signature.inspect}>"
    end
  end
end
