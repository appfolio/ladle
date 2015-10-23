json.array!(@pull_requests) do |pull_request|
  json.extract! pull_request, :id
  json.url pull_request_url(pull_request, format: :json)
end
