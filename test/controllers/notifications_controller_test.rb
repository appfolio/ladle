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

    assert_select '.pull-right', count: 2

    pr = notification2.pull_request
    pr2 = notification1.pull_request
    assert_select 'h4' do |headers|
      assert_match(/\[#{pr.repository.name}\] #{pr.title}/, headers[0])
      assert_match(/\[#{pr2.repository.name}\] #{pr2.title}/, headers[1])
    end
  end
end
