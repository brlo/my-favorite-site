class VersesController < ApplicationController
  skip_before_action :require_login_and_activation

  before_action :require_admin, only: %w[update update_interlinear_word]

  # https://github.com/rails/actionpack-page_caching
  # caches_page :index

  def index_redirect
    path  = "/#{I18n.locale}/#{current_bib_lang()}"
    path += "/#{params[:book_code]}/#{params[:chapter]}/"
    path += "?#{request.query_string}" if request.query_string.present?
    redirect_to path, status: :found # :status => :moved_permanently
  end

  def q_redirect
    # использую вставку названия статьи через CGI.escape потому что иначе какой-то
    # глюк возникает, и rails думает, что я отправляю пользователя на другой сайт, хотя это не так.
    path  =
    if params[:page_path].present?
      "/#{I18n.locale}/#{I18n.locale}/w/#{CGI.escape(params[:page_path].to_s)}"
    else
      "/#{I18n.locale}/#{I18n.locale}/w/q/"
    end
    path += "?#{request.query_string}" if request.query_string.present?
    redirect_to path, status: :found # :status => :moved_permanently
  end

  def index
    if params[:book_code].blank? || params[:chapter].blank?
      show_main_page
    else
      show_chapter
    end
  end

  # HTML-фрагмент со списком авторов и кусочками их трудов, где упоминается стих
  def citations
    @book_code = params[:book_code]
    @chapter = params[:chapter].to_i
    @line = params[:line].to_i
    @authors = ::BibleCitations.new(
      lang: locale_for_content_lang(params[:content_lang]), book_code: @book_code, chapter: @chapter, line: @line
    ).authors
    @address = ::AddressConverter.humanize("#{@book_code}:#{@chapter}:#{@line}")

    render partial: 'verses/citations', layout: false
  end

  def search
    # default
    @search_accuracy = params[:acc] || 'similar'
    @search_lang = params[:l] || current_bib_lang() # ::LOCALE_TO_BIB_LANG[::I18n.locale.to_s]
    @search_books = params[:book]
    # не индексировать
    @no_index = true

    # если это ссылка, то просто найдём её
    if link = ::AddressConverter.search_text_to_link(params[:t])
      redirect_to("/#{I18n.locale}/#{@search_lang}#{link}")
      return
    end

    @search_text = params[:t]
    @verses = params[:t].present? ? fetch_search_results : []
    @matches_count = @verses.count

    @current_menu_item = 'biblia'
    @page_title = ::I18n.t('search_page.title')
    @page_title += ": #{params[:t].to_s[0..20]}" if params[:t].present?
    @meta_description = ::I18n.t('search_page.meta_description', search: @search_text, matches: @matches_count)
    if @verses.presence
      @meta_description +=
      ::I18n.t('search_page.meta_description_first_verse', verse: @verses.first.text.to_s[0..150])
    end
    @meta_book_tags = [params[:t]] if params[:t].present?
    @canonical_url = build_canonical_url("/search/?acc=#{@search_accuracy}&l=#{@search_lang}&t=#{@search_text}")
  end

  def redirect_to_new_address
    # в старых адресах нет ни языка интерфейса, ни языка контента: берём язык Библии по текущей локали
    bib_lang = current_bib_lang().presence || ::LOCALE_TO_BIB_LANG[I18n.locale.to_s]
    redirect_to "/#{I18n.locale}/#{bib_lang}/#{params[:book_code]}/#{params[:chapter]}/", status: 301
  end

  # Redirect: /ru/f/Дан. 1:2 -> /ru/ru/dan/1/#L2
  def goto_verse_by_human_address
    human_address = params[:human_address]
    path = '/'

    if link = ::AddressConverter.human_to_link(human_address)
      path = "/#{I18n.locale}/#{current_bib_lang()}#{link}"
    end

    redirect_to(path)
  end

  # Метод для админа, чтобы дописывать фуригану к японскому переводу
  def update
    verse = Verse.find(params[:id])
    verse_params = params[:verse]
    if verse_params[:text].present? && verse.update(text: verse_params[:text])
      render :json => {successfull: 'ok', text: verse.reload.text}
    else
      render :json => {successfull: 'fail'}, status: 422
    end
  end

  # Метод для админа, чтобы установить новое слово для подстрочника
  def update_interlinear_word
    verse = Verse.find(params[:id])

    # Изменились названия локалей, поэтому когда обращаемся к переводу внутри стиха,
    # ключи en и ru оставляем как есть, а ja подменяем на старый jp:
    if verse.update_interlinear_word!(locale_for_content_lang(), params[:word_index], params[:word])
      render :json => {successfull: 'ok', verse_data: verse.data['wi']}
    else
      render :json => {successfull: 'fail'}, status: 422
    end
  end

  private

  # ГЛАВНАЯ СТРАНИЦА
  def show_main_page
    # для работы переключателя языка
    @current_bib_lang = current_bib_lang()
    @locale_by_bib = locale_for_content_lang(@current_bib_lang)

    @page = ::Page.where(path_low: "links_#{@locale_by_bib.downcase}").first
    if @page&.page_type.to_i == ::Page::PAGE_TYPES['список']
      @tree_menu = @page.tree_menu
    end

    # Первые три стиха из 1ИН, для главной страницы
    @main_verses = ::Verse.where(tr_code: @current_bib_lang, book: '1in', chapter: 1, line: [1,2,3]).order(line: :asc).to_a

    @page_title = ::I18n.t('root_page.title')
    @meta_description = ::I18n.t('about_site_short')
    @canonical_url = "https://bibleox.com/#{I18n.locale}/"

    render 'main'
  end

  # Страница главы Библии. Данные собирает BibleChapterPage, тут раскладываем их по переменным шаблона
  def show_chapter
    chapter = ::BibleChapterPage.new(
      content_lang: current_bib_lang(),
      book_code: params[:book_code] || 'gen',
      chapter: params[:chapter] || 1,
      ui_locale: ::I18n.locale,
    )

    @content_lang = chapter.content_lang
    @is_interliner = chapter.is_interliner?
    @int_content_lang = chapter.interliner_tr_code
    @no_index = true if chapter.no_index?
    @book_code = chapter.book_code
    @chapter = chapter.chapter
    @bible_path = chapter.cache_key
    @is_psalm = chapter.is_psalm?
    @audio_file = chapter.audio_file
    @verses = chapter.verses
    @verses_gr = chapter.verses_gr
    @comments = chapter.comments
    @cite_counts = chapter.cite_counts
    @cite_max = chapter.cite_max
    @cite_min = chapter.cite_min
    @current_menu_item = 'biblia'
    @page_title = chapter.title
    @meta_description = chapter.meta_description
    @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")
    @breadcrumbs = chapter.breadcrumbs
    @meta_book_tags = chapter.meta_book_tags

    respond_to do |format|
      format.html { render 'index' }
    end
  end

  # Результаты поиска по Писанию (до 3000 стихов)
  def fetch_search_results
    searcher =
      if @search_lang.in?(%w[jp-ni cn-ccbs arab-avd heb-osm gr-lxx-byz]) || @search_accuracy == 'exact'
        ::VerseSearchPgroonga
      else
        ::VerseSearch
      end

    searcher.new(
      text: @search_text,
      tr_code: @search_lang,
      book: @search_books,
      accuracy: @search_accuracy,
    ).fetch_objects(3_000)
  end
end
