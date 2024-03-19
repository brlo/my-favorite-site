class PagesController < ApplicationController
  caches_page :show, :about

  def main
    redirect_to "/#{I18n.locale}/#{current_bib_lang()}/lk/1/"
  end

  def list
    @current_menu_item = 'links'
    @content_lang = params[:content_lang]

    path = params[:page_path].to_s
    @page = ::Page.find_by!(path_low: 'main', lang: @content_lang, page_type: 4, is_published: true)
    @canonical_url = build_canonical_url("/w/")

    @page_title = ::I18n.t('page.main_title')
    @meta_description = ::I18n.t('page.main_meta_desc')

    render :index

    # МИГРАЦИЯ ОТ ЦИТАТ К СТРАНИЦАМ
    #
    # ::QuotesPage.each do |qpage|
    #   page = Page.new()
    #   page.lang = 'ru'
    #   page.title = qpage.title
    #   page.meta_desc = qpage.meta_desc
    #   page.body = qpage.body
    #   page.priority = qpage.position
    #   page.path = qpage.path
    #   page.page_type = 1
    #   page.is_published = true
    #   page.save
    # end

    # ::QuotesPage.each do |qpage|
    #   page = Page.find_by(title: qpage.title, priority: qpage.position)
    #   page.is_published = true
    #   page.save
    # end
  end

  def show
    # Название (path) страницы, который ищет клиент
    path = params[:page_path].to_s
    path_downcased = path.downcase
    @content_lang = params[:content_lang]

    # Ищем в БД страницу. Клиент мог неправильно ввести регистр, поэтому ищем
    # в спец поле, где всё в нижнем регистре.
    @page =
    ::Mongo::QueryCache.cache do
      ::Page.find_by(path_low: path_downcased)
    end

    # 404 - документ скрыт или удалён
    if @page
      if @page.is_deleted || (@page.is_published != true)
        not_found!()
      end
    end

    if @page.nil?
      # ########################################################################
      # СТРАНИЦА НЕ НАЙДЕНА — пытаемся найти редирект
      # ########################################################################
      #
      # Если страница не найдена, то попробовать найти страницу,
      # у которой указан наш адрес в качестве её старого адреса
      @page = ::Page.find_by(redirect_from: path_downcased)

      if @page
        redirect_to my_page_link_to("/#{::CGI.escape(@page.path)}")
      else
        # Если страницу всё равно не нашли, то отдаём 404 с предложением создать страницу
        # not_found!()
        render status: 404
      end

    elsif @page.lang == @content_lang
      # ########################################################################
      # СТРАНИЦА НАЙДЕНА и язык совпадает - РЕНДЕРИМ
      # ########################################################################

      # if stale?(last_modified: @page.u_at.utc, etag: @page)
        @canonical_url = build_canonical_url("/w/#{::CGI.escape(@page.path)}")

        @author_name = @page.user&.name
        if @page.editors&.any?
          @editors_names =
          ::Mongo::QueryCache.cache do
            ::User.where(:id.in => @page.editors).pluck(:name)
          end
        end

        # не индексировать, где текст UI не совпадает с текстом контента
        if params[:locale] != params[:content_lang]
          @no_index = true
        end

        # AUDIO: /public/s/audio/pages/ru/fathers/01_ign_ant/ef
        # В статье указать только это: fathers/01_ign_ant/ef
        audio_file = "/s/audio/pages/#{@content_lang}/#{@page.audio}"
        if ::File.exists?("#{Rails.root}/public#{ audio_file }.mp3")
          @audio_link = audio_file
        end

        # В адресе указывается язык UI и отдельно язык контента /:ui/:content/...
        # если язык контента не совпадает с языком статьи, то надо сделать редирект
        # на правильную статью, если она есть, или отдать 404
        if @page.path != path
          # перенаправляем на путь с правильным регистром
          redirect_to @canonical_url, status: :found # :status => :moved_permanently
        end

        # Доступные языки статьи
        @page_langs =
        ::Mongo::QueryCache.cache do
          ::Page.where(group_lang_id: @page.group_lang_id).pluck(:lang, :path)
        end

        # РОДИТЕЛЬ: и всё, что мы можем построить, имея родителя
        if @page.parent_id
          @parent_page =
          ::Mongo::QueryCache.cache do
            ::Page.only(:id, :p_id, :title, :path, :page_type).find_by!(id: @page.parent_id)
          end
        end

        if @parent_page
          if @parent_page.page_type.to_i == ::Page::PAGE_TYPES['список']
            # МЕНЮ: все элементы меню родителя
            menus =
            ::Mongo::QueryCache.cache do
              ::Menu.where(page_id: @parent_page.id).to_a
            end
            menus_by_id = {}
            menus_by_path = {}
            menus_by_parent_id = ::Hash.new([])
            parent_ids_with_links = ::Hash.new([])

            menus.each do |menu|
              # индексация по ID
              menus_by_id[menu.id] = menu
              # индексация по PATH
              menus_by_path[menu.path] = menu
              # поиск всех parent_id, имеющих детей с path
              if menu.path.present? && menu.parent_id.present?
                parent_ids_with_links[menu.parent_id] += [menu]
              end
            end

            # сортируем
            parent_ids_with_links.each do |p_id, group|
              parent_ids_with_links[p_id] =
              parent_ids_with_links[p_id].sort_by { |m| m.priority.to_i }
            end

            # Здесь отрисовывали меню при клике на заголвоок статьи h1.
            # От которого решили избавиться, чтобы упростить восприятие UI.
            # Посчитали, что нормальных хлебных крошек достаточно.
            #
            # # ТРУДЫ АВТОРА: корневые элементы меню (будем считать, что это труды автора)
            # @parent_books =
            # parent_ids_with_links.map do |p_id, children_with_links|
            #   parent = menus_by_id[p_id]
            #   # next if el.nil?

            #   # ссылка из первого вложенного элемента
            #   first_child_with_link = children_with_links.first.path
            #   # next if first_child_with_link.nil?

            #   # название от родителя, а ссылка от первого потомка
            #   # Перейдя по такой ссылке, мы окажемся на странице потомка,
            #   # а под его заголовком будут отрисованы все дочерние элементы родителя,
            #   # при этом в меню, которое вызывается при клике на заголовок потомка,
            #   # отрисовываются все родители, имеющие потомков, переходя к которым
            #   # увидим возможность также переключаться между соседнимипотомками.
            #   [ parent.title, first_child_with_link ]
            # end

            # ЭТА СТРАНИЦА. элемент текущей страницы в меню
            @page_in_menu = menus_by_path[@page.path]

            # ГЛАВЫ. все соседи данной страницы в меню (будем считать, что это главы)
            if @page_in_menu
              siblings_and_me = parent_ids_with_links[@page_in_menu.parent_id]
              # соседи из меню (одинаковый родитель)
              @chapters = siblings_and_me.map { |m| [m.title, m.path] }

              # сохраняем индексы глав в массиве с главами
              my_ix_in_menu = siblings_and_me.index(@page_in_menu)
              if my_ix_in_menu
                @chapter_current = my_ix_in_menu + 1
              end
              # @chapter_prev = @chapter_current - 1
              # @chapter_next = @chapter_current + 1
            end
          end
        end

        if @page.page_type.to_i == ::Page::PAGE_TYPES['список']
          @tree_menu = @page.tree_menu
        end

        # ХЛЕБНЫЕ КРОШКИ
        @breadcrumbs = []
        if @parent_page
          # родитель родителя статьи
          if @parent_page.parent_id
            @pg1 =
            ::Mongo::QueryCache.cache do
              ::Page.only(:id, :p_id, :title, :path).find_by!(id: @parent_page.parent_id)
            end

            # родитель родителя родителя статьи
            if @pg1.parent_id
              @pg2 =
              ::Mongo::QueryCache.cache do
                ::Page.only(:id, :p_id, :title, :path).find_by!(id: @pg1.parent_id)
              end
              @breadcrumbs << [@pg2.title, @pg2.path]
            end

            @breadcrumbs << [@pg1.title, @pg1.path]
          end

          # родитель статьи
          @breadcrumbs << [@parent_page.title, @parent_page.path]
        end

        @breadcrumbs << [@page.title, nil]

        # Стихи страницы (как в Библии), если есть
        @verses = @page.verses

        @page_title = ::I18n.t('page.title', term: @page.title)
        @meta_description = @page.meta_desc
        @current_menu_item = 'links'

        @chapter_current ||= 1

        # Если текст этой статьи разбит на несколько глав,
        # то имеем такую ситуацию на странице:
        # есть много маленьких глав со сплошной нумерацией (стихи пронумерованы подряд от первой до последней главы)
        # и если выделить стихи из разных глав, то как при копировании указывать главу? Никак.
        # вот и прячем тогда главу вообще. Указываем только номер стиха.
        if @verses.present? && @verses.count > 1
          @is_disable_chapters = true
        end
      # end
    else
      # ########################################################################
      # СТРАНИЦА НЕ НАЙДЕНА но возможно получится найти подходящую к этому языку страницу
      # ########################################################################
      #
      # Страницу нашли, но язык не тот, поэтому пытаемся отправить
      # пользователя на параллельную страницу с тем языком, который он искал
      @page =
      ::Mongo::QueryCache.cache do
        ::Page.find_by!(group_lang_id: @page.group_lang_id, lang: @content_lang)
      end
      redirect_to my_page_link_to("/#{::CGI.escape(@page.path)}")
    end
  end

  def about
    @page_title = I18n.t('about_site')
    @meta_description = I18n.t('about_site_description')
    @canonical_url = build_canonical_url('/about/')
  end
end
