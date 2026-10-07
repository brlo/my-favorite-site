require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user is created with api token and site provider" do
    user = create_user
    assert_equal 'site', user.provider
    assert user.api_token.present?
    assert user.activated?
  end

  test "email is required for site users and must be unique" do
    assert_not User.new(name: 'No Mail', password: 'secret123', password_confirmation: 'secret123').valid?
    first = create_user
    dup = User.new(name: 'Dup User', email: first.email, password: 'secret123', password_confirmation: 'secret123')
    assert_not dup.valid?
    assert dup.errors[:email].any?
  end

  test "plus subaddressing in email is rejected" do
    user = User.new(name: 'Plus User', email: 'a+b@example.com', password: 'secret123', password_confirmation: 'secret123')
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "short password is rejected" do
    user = User.new(name: 'Short Pass', email: 'short@example.com', password: '123', password_confirmation: '123')
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "username is generated from name and made unique" do
    a = create_user(name: 'Ivan Petrov', username: nil)
    b = create_user(name: 'Ivan Petrov', username: nil)
    assert_equal 'ivan_petrov', a.username
    assert_equal 'ivan_petrov_1', b.username
  end

  test "ability? is false without privileges, true after can!, false after cant!" do
    user = create_user
    assert_not user.ability?('pages_read')
    user.can!('pages_read')
    assert user.ability?('pages_read')
    assert_not user.ability?('pages_create')
    user.cant!('pages_read')
    assert_not user.ability?('pages_read')
  end

  test "super privilege and admin flag allow everything" do
    sup = create_user
    sup.can!('super')
    assert sup.ability?('dict_destroy')
    assert_equal User::PRIVS.keys.sort, sup.privs_list.keys.sort

    admin = create_user(is_admin: true)
    assert admin.ability?('anything')
  end

  test "privs_list contains only granted privileges" do
    user = create_user
    user.can!('dict_read')
    assert_equal({ 'dict_read' => true }, user.privs_list)
  end

  test "admin_area_access? requires a read privilege, page ownership or admin and no block" do
    user = create_user
    assert_not user.admin_area_access?
    user.can!('gallery_read')
    assert user.admin_area_access?
    user.update!(is_blocked: true)
    assert_not user.admin_area_access?

    assert create_user(pages_owner: [1]).admin_area_access?
  end

  test "allow_ip? allows everything when the list is empty" do
    user = create_user
    assert user.allow_ip?('1.2.3.4')
    user.update!(allow_ips: ['10.0.0.1'])
    assert user.allow_ip?('10.0.0.1')
    assert_not user.allow_ip?('1.2.3.4')
  end

  test "get_api_token generates a token when it is blank" do
    user = create_user
    user.update_columns(api_token: '')
    token = user.get_api_token
    assert_match(/\A\h{8}-/, token)
    assert_equal token, user.reload.api_token
  end
end
