module Admin
  class BaseController < ApplicationController
    before_action :auth
    before_action :admin_vars
    before_action :reject_not_admins

    def auth
      if !logged_in?()
        redirect_to login_path
      end
    end

    def admin_vars
      @no_index = true
      @page_title = "Админка"
    end

    def reject_not_admins
      if ::Current.user.is_admin != true
        raise ActionController::RoutingError.new('Not Found')
      end
    end
  end
end
