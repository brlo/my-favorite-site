class PagesController < ApplicationController
  skip_before_action :require_login_and_activation

  # Чтобы начать создавать html-файды для работы от кэша, просто раскоментируй:
  # А nginx уже настроен так, чтобы отдавать эти файлы, если они есть.
  # caches_page :show, :about

  def main
    redirect_to "/#{I18n.locale}/"
  end

  def show
    # Название (path) страницы, который ищет клиент
    path = params[:page_path].to_s
    @content_lang = params[:content_lang]

    # Ищем в БД страницу. Клиент мог неправильно ввести регистр, поэтому ищем
    # в спец поле, где всё в нижнем регистре.
    @page = ::Page.where(path_low: path.downcase).first

    return show_missing_page(path.downcase) if @page.nil?
    # 404 - документ скрыт или удалён
    return render_not_found() if @page.is_deleted || @page.is_published != true
    return redirect_to_translation if @page.lang != @content_lang

    # перенаправляем на путь с правильным регистром
    # (canonical_url абсолютный, Rails не пустит на другой хост, поэтому ссылка локальная)
    return redirect_to(page_path_link(@page), status: :found) if @page.path != path

    prepare_page_view

    # если страница с небольшим кол-вом текста (до 40 символов), то показываем её, но со статусом 404 (чтобы поисковик правильно нас понял)
    render status: 404 if @page.is_body_empty?
  end

  def search
    # не индексировать
    @no_index = true

    # search page
    # Название (path) страницы, которые ищет клиент
    path = params[:page_path].to_s
    path_downcased = path.downcase
    @content_lang = params[:content_lang]

    # Ищем в БД страницу. Клиент мог неправильно ввести регистр, поэтому ищем
    # в спец поле, где всё в нижнем регистре.
    @page = ::Page.find_by(path_low: path_downcased, lang: @content_lang)

    if params[:t].present?
      @search_text = params[:t]
      @page_number = params[:page]&.to_i || 1
      @per_page = 10
      offset = (@page_number - 1) * @per_page

      # Запрашиваем результаты из БД
      # searcher = @page.lang == 'ru' ? ::PageParagraphSearch : ::PageParagraphSearchPgroonga
      searcher = ::PageParagraphSearchPgroonga
      search_service = searcher.new(
        start_page: @page,
        text: @search_text,
      )
      @matches = search_service.fetch_objects(limit: @per_page, offset: offset)
      @matches_count = search_service.count if @page_number == 1
    else
      @search_text = params[:t]
      @matches = []
      @matches_count = 0
    end

    @current_menu_item = 'links'
    @page_title = ::I18n.t('search_page.title')
    @page_title += ": #{@page.title.to_s[0..20]}" if params[:t].present?
    @meta_description = ::I18n.t('search_page.meta_description', search: @search_text, matches: @matches_count)

    @meta_book_tags = [params[:t]] if params[:t].present?
    @canonical_url = build_canonical_url("/w/#{::CGI.escape(@page.path)}/search?t=#{@search_text}")

    respond_to do |format|
      format.html
      format.turbo_stream {
        if @matches.present?
          render turbo_stream: turbo_stream.append(
            'search-results',
            partial: 'pages/match',
            collection: @matches,
            as: :m
          )
        else
          render turbo_stream: turbo_stream.replace(
            'infinite-scroll-trigger', partial: 'pages/end_of_results'
          )
        end
      }
    end
  end

  def page_as_pdf
    # Название (path) страницы, который ищет клиент
    path = params[:page_path].to_s
    path_downcased = path.downcase

    @page = ::Page.find_by(path_low: path_downcased)

    if @page.nil?
      render_not_found()
    else
      # path_to_pdf = ::PdfGenerator.path_to_page_pdf(@page)
      if @page.pdf_exists?
        path_to_pdf =  "/#{@page.pdf_path}"
        # Перенаправление пользователя на скачивание файла
        redirect_to my_res_link_to(path_to_pdf), allow_other_host: true, status: :found
      else
        render_not_found()
      end
    end
  end

  def about
    @page_title = I18n.t('about_site')
    @meta_description = I18n.t('about_site_description')
    @canonical_url = build_canonical_url('/about/')
  end

  private

  def page_path_link(page)
    my_page_link_to("/#{::CGI.escape(page.path)}")
  end

  # Страницы нет: ищем, не переехала ли она (старый адрес), или предлагаем создать
  def show_missing_page(path_downcased)
    # Если страница не найдена, то попробовать найти страницу,
    # у которой указан наш адрес в качестве её старого адреса
    @page = ::Page.where(redirect_from: path_downcased).first
    return redirect_to(page_path_link(@page)) if @page

    # Собираем ссылка на админку, для быстрого заполнения полей при создании страницы.
    # Пояснение: когда мы хотим создавать страницы, мы сначала добавляем в меню родительской страницы
    # элемент без path. Потом из меню переходим по этой ссылке и попадаем на 404, где предлагается создать страницу.
    # В этот момент у нас в path есть необходимые параметры для предзаполнения полей, которые мы сейчас вот тут и обрабываем.
    @link_to_create = new_admin_page_path(
      locale: nil,
      page_title: params[:page_path].to_s.gsub(/[^\p{L}0-9_\-\s\(\)\,]/, ''),
      lang: @content_lang,
      menu_id: params[:menu_id].presence,
      parent_id: params[:parent_id].presence,
    )
    render status: 404
  end

  # Страницу нашли, но язык не тот: отправляем на параллельную страницу с тем языком, который искал пользователь
  def redirect_to_translation
    @page = ::Page.find_by!(group_lang_id: @page.group_lang_id, lang: @content_lang)
    redirect_to page_path_link(@page)
  end

  # Раскладываем данные страницы по переменным шаблона
  def prepare_page_view
    @canonical_url = build_canonical_url("/w/#{::CGI.escape(@page.path)}")

    @author_name = @page.user&.name
    @editors_names = ::User.where(id: @page.editors).pluck(:name) if @page.editors&.any?

    # не индексировать, где текст UI не совпадает с текстом контента
    @no_index = true if params[:locale] != params[:content_lang]

    @audio_link = @page.audio_link(@content_lang)

    # Доступные языки статьи
    @page_langs = ::Page.where(group_lang_id: @page.group_lang_id).pluck(:lang, :path).to_h

    prepare_navigation

    if @page.page_type.to_i == ::Page::PAGE_TYPES['список']
      @tree_menu = @page.tree_menu
      @menus_info = @page.menus_info
    end

    # Стихи страницы (как в Библии), если есть
    @verses = @page.verses

    @page_title = build_page_title
    @meta_description = @page.meta_desc
    @current_menu_item = 'links'

    prepare_bible_comment if @page.is_page_bib_comment?

    # Если текст этой статьи разбит на несколько глав,
    # то имеем такую ситуацию на странице:
    # есть много маленьких глав со сплошной нумерацией (стихи пронумерованы подряд от первой до последней главы)
    # и если выделить стихи из разных глав, то как при копировании указывать главу? Никак.
    # вот и прячем тогда главу вообще. Указываем только номер стиха.
    @is_disable_chapters = true if @verses.present? && @verses.count > 1
  end

  # РОДИТЕЛЬ и всё, что мы можем построить, имея родителя: главы из меню и хлебные крошки
  def prepare_navigation
    navigation = ::PageNavigation.new(@page)
    @parent_page = navigation.parent_page

    if (chapters = navigation.chapters)
      @page_in_menu = chapters.page_in_menu
      @chapters = chapters.items
      @chapter_current = chapters.current
    end
    @chapter_current ||= 1

    @breadcrumbs = navigation.ancestors.map { |pg| [pg.title, my_page_link_to(pg.path, page_lang: pg.lang)] }
    @breadcrumbs << [@page.title]
  end

  def build_page_title
    title = ::I18n.t('page.title', term: @page.title)
    return title unless title.length < 30 && @parent_page.present?

    # добавить в заголовок несколько слов из заголовка родителя, сколько поместится в 25 символов
    # если слово уже не помещается, то ставим три точки и выходим из цикла
    parent_part = ''
    @parent_page.title.split(' ').each do |word|
      if (parent_part.length + word.length) < 25
        parent_part += " #{word}"
      else
        parent_part += '...'
        break
      end
    end
    "#{title} / #{parent_part}"
  end

  # Если это коммент к библейскому стиху, то надо переделать хлеб. крошки, заголовок и активное меню
  def prepare_bible_comment
    @current_menu_item = 'biblia'

    book_code = @page.path_low.split(':').first.split('-').last
    @breadcrumbs = [
      ::I18n.t('breadcrumbs.bible'),
      ::I18n.t(::BOOKS[book_code][:zavet] == 1 ? 'breadcrumbs.VZ' : 'breadcrumbs.NZ'),
      @page.title,
    ]
    @page_title = "#{@page.title} / #{::I18n.t('bible_page.comment_title')}"
  end
end
