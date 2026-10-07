require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    ActionMailer::Base.deliveries.clear
  end

  test "new shows the form" do
    get new_password_reset_path(locale: 'ru')
    assert_response :success
  end

  test "create answers the same way for known and unknown emails" do
    post password_resets_path(locale: 'ru'), params: { email: 'nobody@example.com' }
    assert_redirected_to login_path(locale: 'ru')
    assert_no_enqueued_jobs

    post password_resets_path(locale: 'ru'), params: { email: @user.email }
    assert_redirected_to login_path(locale: 'ru')
    assert_not_nil @user.reload.reset_password_token
  end

  test "edit with unknown token does not show the form" do
    get edit_password_reset_path('bad-token', locale: 'ru')
    assert_response :redirect
  end

  test "update changes the password with a valid token" do
    @user.deliver_reset_password_instructions!
    token = @user.reload.reset_password_token

    patch password_reset_path(token, locale: 'ru'),
          params: { user: { password: 'newsecret1', password_confirmation: 'newsecret1' } }
    assert_redirected_to login_path(locale: 'ru')
    assert User.authenticate(@user.email, 'newsecret1')
    assert_nil @user.reload.reset_password_token
  end

  test "update rejects a mismatched confirmation" do
    @user.deliver_reset_password_instructions!
    token = @user.reload.reset_password_token

    patch password_reset_path(token, locale: 'ru'),
          params: { user: { password: 'newsecret1', password_confirmation: 'different' } }
    assert_response :unprocessable_entity
    assert_not User.authenticate(@user.email, 'newsecret1')
  end
end
