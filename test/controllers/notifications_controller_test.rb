require 'test_helper'

class NotificationsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "index" do
    notification1 = create(:notification)
    notification1.notified_users << @user
    notification1.save!

    notification2 = create(:notification)
    notification2.notified_users << @user
    notification2.save!

    get :index
    assert_response :success

    notifications = assigns(:notifications)
    assert_equal 2, notifications.size

    notification2_presenter = notifications.first
    assert_equal notification2, notification2_presenter.__getobj__

    notification1_presenter = notifications.last
    assert_equal notification1, notification1_presenter.__getobj__
  end
end
