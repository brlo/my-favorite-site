class CurrentUser
  def initialize(user)
    @user = user
  end

  def id
    @user._id
  end

  def name
    @user&.name
  end

  def username
    @user&.username
  end

  def allow_ips
    @user&.allow_ips
  end

  def is_admin
    @user&.is_admin
  end

  def instance
    @user
  end

  def logged_in?
    !@user.nil?
  end

  def ability?(action)
    @user&.ability?(action)
  end

  def privs_list
    @user&.privs_list || {}
  end

  def pages_owner
    @user&.pages_owner || {}
  end
end
