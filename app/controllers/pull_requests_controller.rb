class PullRequestsController < ApplicationController
  before_action :set_pull_request, only: [:show, :edit, :update, :destroy]

  def index
    @pull_requests = PullRequest.all
  end

  def show
  end

  def destroy
    @pull_request.destroy
    respond_to do |format|
      format.html { redirect_to pull_requests_url, notice: 'Pull request was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_pull_request
    @pull_request = PullRequest.find(params[:id])
  end

  def pull_request_params
    params[:pull_request]
  end
end
