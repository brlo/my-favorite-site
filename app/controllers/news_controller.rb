class NewsController < ApplicationController
  skip_before_action :require_login_and_activation

  PER_PAGE = 10
  READING_LIMIT = 5
  READING_CANDIDATES = 20
  RECENTLY_UPDATED_LIMIT = 5

  # Лента статей с флагом «новостная лента». Показываем только язык текущего
  # интерфейса — как в каталоге тегов: у каждой языковой версии своя лента.
  def index
    @pages = ::Page.news_feed
      .where(lang: lang, page_type: ::Page::PAGE_TYPES['статья'])
      .where('COALESCE(LENGTH(pages.body), 0) >= 40')
      .includes(:user, :tags, :parent)
      .order(created_at: :desc, id: :desc)
      .page(params[:page]).per(PER_PAGE)

    page_ids = @pages.map(&:id)
    @reaction_counts = ::PageReaction.counts_for(page_ids)
    @my_reactions = ::PageReaction.kinds_for(request.ip, page_ids)

    prepare_reading_now
    prepare_recently_updated

    @page_title = ::I18n.t('news.title')
    @meta_description = ::I18n.t('news.meta_description')
    @canonical_url = build_canonical_url('/news')
    @current_menu_item = 'news'
  end

  # Живой блок «Читают сейчас»: его обновляет Stimulus-контроллер раз в минуту
  def reading_now
    prepare_reading_now
    response.headers['Cache-Control'] = 'no-store'
    response.headers['X-Robots-Tag'] = 'noindex'
    render partial: 'news/reading_now', layout: false
  end

  private

  # Статьи ленты показываем на языке текущей локали интерфейса
  def lang
    ::I18n.locale.to_s
  end

  # Свежие правки других статей — дополнение к ленте, без повторов с текущей страницей
  def prepare_recently_updated
    scope = ::Page.published
      .where(lang: lang, is_deleted: [nil, false], page_type: ::Page::PAGE_TYPES['статья'])
      .where('COALESCE(LENGTH(pages.body), 0) >= 40')

    feed_ids = @pages.map(&:id)
    scope = scope.where.not(id: feed_ids) if feed_ids.any?

    @recently_updated = scope
      .order(updated_at: :desc, id: :desc)
      .limit(RECENTLY_UPDATED_LIMIT)
      .select(:id, :title, :path, :lang, :updated_at)
  end

  # @reading_now — [[:page, page, count] | [:bible, [код перевода, код книги], count], ...] по убыванию,
  # @reading_now_total — читателей на сайте (все языки и книги Библии)
  def prepare_reading_now
    data = ::PageVisits.reading_now(limit: READING_CANDIDATES)
    @reading_now_total = data.total_readers

    page_ids = data.pages.map(&:first)
    pages = if page_ids.any?
              ::Page.where(id: page_ids, is_published: true, is_deleted: [nil, false])
                .select(:id, :title, :path, :lang).index_by(&:id)
            else
              {}
            end

    items = data.pages.filter_map do |page_id, count|
      page = pages[page_id]
      [:page, page, count] if page
    end
    items += data.bibles.map { |content_lang, book_code, count| [:bible, [content_lang, book_code], count] }
    @reading_now = items.sort_by { |type, _item, count| [-count, type == :page ? 0 : 1] }.first(READING_LIMIT)
  end
end
