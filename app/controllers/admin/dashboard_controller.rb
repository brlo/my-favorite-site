module Admin
  class DashboardController < BaseController
    def show
      @week_visits = ::PageVisits.week_visits

      # вчерашняя статистика: сутки уже закрыты, числа не меняются
      @yesterday = Date.yesterday
      @day_bots = ::PageVisits.day_bots(@yesterday)
      @day_langs = ::PageVisits.day_langs(@yesterday)
      @day_top_ips = ::PageVisits.day_top_ips(@yesterday)

      if can?('pages_read')
        @pages = ::Page.order(updated_at: :desc).limit(7).to_a
        @page_visits = ::PageVisits.visits(@pages.map(&:id)) if @pages.any?

        day_top = ::PageVisits.day_top_pages(@yesterday).first(10)
        titles = ::Page.where(id: day_top.map(&:first)).pluck(:id, :title).to_h
        @day_top_pages = day_top.map { |id, count| [titles[id.to_i], count] }

        prepare_reading_now
      end

      if current_user.is_admin?
        @users_total = ::User.count
        @users_pending = ::User.where.not(activation_state: 'active').where.not(email: [nil, '']).count
        @users_new = ::User.order(created_at: :desc).limit(5)
      end
    end

    private

    # Статьи на всех языках, которые читают прямо сейчас (общий Redis-ключ «reading»)
    def prepare_reading_now
      data = ::PageVisits.reading_now(limit: 30)
      @reading_now_total = data.total_readers

      ids = data.pages.map(&:first)
      pages = if ids.any?
                ::Page.where(id: ids, is_published: true, is_deleted: [nil, false],
                             page_type: ::Page::PAGE_TYPES['статья'])
                  .select(:id, :title, :lang).index_by(&:id)
              else
                {}
              end

      @reading_now = data.pages.filter_map { |id, count| [pages[id], count] if pages[id] }.first(10)
    end
  end
end
