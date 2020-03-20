require 'test_helper'

class UserSettingsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user)
    sign_in @user
  end

  test "edit" do
    GithubStubs.stub_emails(@user.token)
    get :edit
    assert_response :success

    view = assigns(:view)

    assert_equal @user, view.user
    assert_equal ["dhh@rails.com", "dhh@internet.com"], view.emails
  end

  test "update success" do
    patch :update, params: { user: {email: "zima@somethingdifferent.com"} }
    assert_redirected_to edit_user_settings_path

    @user.reload
    assert_equal "zima@somethingdifferent.com", @user.email
  end

  test "update missing parameters - user" do
    raised = assert_raises(ActionController::ParameterMissing) do
      patch :update
    end

    assert_equal :user, raised.param
  end

  test "update missing parameters - email" do
    GithubStubs.stub_emails(@user.token)
    patch :update, params: { user: {biz: :baz} }
    assert_response :unprocessable_entity

    view = assigns(:view)

    assert_equal @user, view.user
    assert_equal ["dhh@rails.com", "dhh@internet.com"], view.emails

    assert_equal [:email], view.user.errors.keys
    assert_equal ["can't be blank"], view.user.errors[:email]
  end
end
