class HomeController < AuthenticatedController
  def index
    @pull_requests = PullRequest.all.order('created_at desc').limit(20)
  end
end
