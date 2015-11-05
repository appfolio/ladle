class UserSettingsController < AuthenticatedController
  class UserSettingsView
    attr_reader :user, :emails

    def initialize(user, emails)
      @user   = user
      @emails = emails
    end
  end

  def edit
    create_edit_view(current_user)
  end

  def update
    user_params = params.require(:user).permit(:email)
    email = user_params[:email]

    user = current_user
    user.email = email
    user.save!

    flash.notice = "Settings successfully updated."
    redirect_to edit_user_settings_path
  rescue ActiveRecord::RecordInvalid => e
    flash.now.alert = "Failed updating settings."
    create_edit_view(e.record)
    render :edit, status: :unprocessable_entity
  end

  private

  def create_edit_view(user)
    @view = UserSettingsView.new(user, notification_emails(user))
  end

  def notification_emails(user)
    client = Octokit::Client.new(access_token: user.token)

    verified_emails = client.emails.select(&:verified)

    emails = verified_emails.map(&:email)

    emails.reject do |email|
      email =~ /github\.com$/
    end
  end
end
