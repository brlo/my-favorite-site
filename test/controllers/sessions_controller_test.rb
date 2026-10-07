require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = create_user(password: 'secret123', password_confirmation: 'secret123') }

  def login_params(email, password)
    { session: { email: email, password: password } }
  end

  test "new renders the login form" do
    get login_path(locale: 'ru')
    assert_response :success
  end

  test "valid credentials log the user in" do
    post login_path(locale: 'ru'), params: login_params(@user.email, 'secret123')
    assert_response :redirect
    get profile_path(locale: 'ru')
    assert_response :success
  end

  test "wrong password is rejected" do
    post login_path(locale: 'ru'), params: login_params(@user.email, 'wrong-pass')
    assert_response :unprocessable_entity
  end

  test "unknown email is rejected" do
    post login_path(locale: 'ru'), params: login_params('nobody@example.com', 'secret123')
    assert_response :unprocessable_entity
  end

  test "logout ends the session" do
    post login_path(locale: 'ru'), params: login_params(@user.email, 'secret123')
    delete logout_path(locale: 'ru')
    assert_redirected_to login_path(locale: 'ru')
  end
end
