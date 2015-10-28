class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def github
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if user_is_permitted_to_login?(@user)
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "Github") if is_navigational_format?
    else
      session["devise.github_data"] = request.env["omniauth.auth"]
      set_flash_message(:alert, :failure, kind: "Github", reason: "your account does not have access") if is_navigational_format?
      redirect_to new_user_session_path
    end
  end

  private

  def user_is_permitted_to_login?(user)
    if ! user.persisted?
      return false
    end

    github_client = Octokit::Client.new(access_token: user.token)
    organizations = github_client.orgs.map { |org| org[:login] }

    Rails.application.github_config.organization_permitted?(organizations)
  end
end
