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

    assert_select "form#edit_user_#{@user.id}"
    assert_select 'option' do |options|
      assert_equal 'dhh@rails.com', options[0].text
      assert_equal 'dhh@internet.com', options[1].text
    end
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

    assert_select "form#edit_user_#{@user.id}"
    assert_select 'option' do |options|
      assert_equal 'dhh@rails.com', options[0].text
      assert_equal 'dhh@internet.com', options[1].text
    end
    assert_select '.user_email.has-error', count: 1, text: /can't be blank/
  end
end
