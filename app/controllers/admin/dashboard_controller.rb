module Admin
  class DashboardController < BaseController
    def show
      @week_visits = ::PageVisits.week_visits

      if can?('pages_read')
        @pages = ::Page.order(updated_at: :desc).limit(7).to_a
        @page_visits = ::PageVisits.visits(@pages.map(&:id)) if @pages.any?
      end

      if current_user.is_admin?
        @users_total = ::User.count
        @users_pending = ::User.where.not(activation_state: 'active').where.not(email: [nil, '']).count
        @users_new = ::User.order(created_at: :desc).limit(5)
      end
    end
  end
end
