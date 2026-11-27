module Admin
  class DashboardController < BaseController
    # Сколько последних реакций показывать в сводке
    REACTIONS_LIMIT = 10

    # Дневная статистика посещений за дату: боты, языки, топ IP и топ статей
    DayStats = Struct.new(:date, :bots, :langs, :top_ips, :top_pages, keyword_init: true)

    def show
      @week_visits = ::PageVisits.week_visits

      # «Сегодня» — незакрытые сутки (цифры растут), «вчера» — закрытые.
      # Пишутся обе сводки в одни и те же дневные ключи Redis: различается только дата.
      today = Date.today
      yesterday = Date.yesterday
      @today_stats = day_stats(today)
      @yesterday_stats = day_stats(yesterday)

      if can?('pages_read')
        @pages = ::Page.order(updated_at: :desc).limit(7).to_a
        @page_visits = ::PageVisits.visits(@pages.map(&:id)) if @pages.any?

        @today_stats.top_pages = top_pages(today)
        @yesterday_stats.top_pages = top_pages(yesterday)

        prepare_bible_visits(today, yesterday)
        prepare_reading_now
        prepare_reactions
      end

      if current_user.is_admin?
        @users_total = ::User.count
        @users_pending = ::User.where.not(activation_state: 'active').where.not(email: [nil, '']).count
        @users_new = ::User.order(created_at: :desc).limit(5)
      end
    end

    private

    # Дневной срез без топа статей: его считаем отдельно и только при праве pages_read
    def day_stats(date)
      DayStats.new(
        date: date,
        bots: ::PageVisits.day_bots(date),
        langs: ::PageVisits.day_langs(date),
        top_ips: ::PageVisits.day_top_ips(date)
      )
    end

    # топ статей за дату: [[название, просмотры], ...]
    def top_pages(date)
      day_top = ::PageVisits.day_top_pages(date).first(10)
      titles = ::Page.where(id: day_top.map(&:first)).pluck(:id, :title).to_h
      day_top.map { |id, count| [titles[id.to_i], count] }
    end

    # Читатели переводов Библии: всего и за сегодня/вчера (heartbeat главы)
    def prepare_bible_visits(today, yesterday)
      @bible_visits = ::PageVisits.bible_visits
      @today_bible_visits = ::PageVisits.day_top_bibles(today)
      @yesterday_bible_visits = ::PageVisits.day_top_bibles(yesterday)
    end

    # Страницы всех языков и книги Библии, которые читают прямо сейчас (общий Redis-ключ «reading»)
    def prepare_reading_now
      data = ::PageVisits.reading_now(limit: 30)
      @reading_now_total = data.total_readers

      ids = data.pages.map(&:first)
      pages = if ids.any?
                ::Page.where(id: ids, is_published: true, is_deleted: [nil, false])
                  .select(:id, :title, :lang).index_by(&:id)
              else
                {}
              end

      @reading_now = data.pages.filter_map { |id, count| [pages[id], count] if pages[id] }.first(10)
      @reading_now_bibles = data.bibles
    end

    # Последние реакции читателей: одна реакция на IP, поэтому это число людей, а не просмотров.
    def prepare_reactions
      @reactions_total = ::PageReaction.count
      @reactions_week = ::PageReaction.where(created_at: 7.days.ago..).count

      by_kind = ::PageReaction.group(:kind).count
      @reaction_counts = ::PageReaction::KINDS.keys.index_with { |kind| by_kind[kind].to_i }

      @reactions = ::PageReaction.includes(:page)
        .order(created_at: :desc, id: :desc)
        .limit(REACTIONS_LIMIT)
        .to_a
    end
  end
end
