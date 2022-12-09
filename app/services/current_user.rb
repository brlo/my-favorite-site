class CurrentUser
  def initialize(user)
    @user = user
  end

  def id
    @user._id.to_s
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
end
