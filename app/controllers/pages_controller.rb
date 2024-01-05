class PagesController < ApplicationController
  def main
    redirect_to "/#{I18n.locale}/#{current_bib_lang()}/gen/1/"
  end

  def list
    path = params[:page_path].to_s
    @pages = ::Page.where(page_type: 4, published: true).limit(100).to_a
    @canonical_url = build_canonical_url("/w/")

    @page_title = ::I18n.t('page.main_title')
    @meta_description = ::I18n.t('page.main_meta_desc')
    @current_menu_item = 'articles'
    @content_lang = params[:content_lang]

    render :index
  end

  def show
    # Название (path) страницы, который ищет клиент
    path = params[:page_path].to_s
    # Ищем в БД страницу. Клиент мог неправильно ввести регистр, поэтому ищем
    # в спец поле, где всё в нижнем регистре.
    @page = ::Page.find_by(path_low: path.downcase)
    @content_lang = params[:content_lang]

    if @page.nil?
      # Если страница не найдена, то попробовать найти страницу,
      # у которой указан наш адрес в качестве её старого адреса
      @page = ::Page.find_by(redirect_from: path)
      if @page
        redirect_to my_page_link_to("/#{@page.path}")
      else
        # Если страницу всё равно не нашли, то отдаём 404
        raise(::Mongoid::Errors::DocumentNotFound)
      end

    elsif @page.lang == @content_lang

      @canonical_url = build_canonical_url("/w/#{@page.path}")

      # В адресе указывается язык UI и отдельно язык контента /:ui/:content/...
      # если язык контента не совпадает с языком статьи, то надо сделать редирект
      # на правильную статью, если она есть, или отдать 404
      if @page.path != path
        # перенаправляем на путь с правильным регистром
        redirect_to @canonical_url, status: :found # :status => :moved_permanently
      end

      # Доступные языки статьи
      @page_langs = ::Page.where(group_lang_id: @page.group_lang_id).pluck(:lang, :path)

      # РОДИТЕЛЬ: и всё, что мы можем построить, имея родителя
      if @page.parent_id
        @parent_page = ::Page.only(:id, :title, :path, :page_type).
          find_by!(id: @page.parent_id)
      end

      if @parent_page
        if @parent_page.page_type.to_i == ::Page::PAGE_TYPES['список']
          # МЕНЮ: все элементы меню родителя
          menus = ::Menu.where(page_id: @parent_page.id).to_a
          # ТРУДЫ АВТОРА: корневые элементы меню (будем считать, что это труды автора)
          @parent_books = menus.select{ |m| m.parent_id == nil }.map { |m| [m.title, m.path] }
          # ЭТА СТРАНИЦА: элемент текущей страницы в меню
          @page_in_menu = menus.find{ |m| m.path == @page.path }
          @parent_page_in_menu = menus.find{ |m| m.id == @page_in_menu.parent_id }

          # ГЛАВЫ: все соседи данной страницы в меню (будем считать, что это главы)
          if @page_in_menu
            # соседи из меню (одинаковый родитель)
            @chapters = menus.
              select{ |m| m.parent_id == @page_in_menu.parent_id }.
              map { |m| [m.title, m.path] }.
              sort_by { |title, path| title }

            # сохраняем индексы глав в массиве с главами
            @chapter_current = @chapters.index([@page_in_menu.title, @page_in_menu.path])
            @chapter_prev = @chapter_current - 1
            @chapter_next = @chapter_current + 1
          end
        end
      end

      if @page.page_type.to_i == ::Page::PAGE_TYPES['список']
        @tree_menu = @page.tree_menu
      end

      # ХЛЕБНЫЕ КРОШКИ
      @breadcrumbs = [::I18n.t('tags.articles'), @page_parent&.title, @page_in_menu&.first].compact

      # Стихи страницы (как в Библии), если есть
      @verses = @page.verses

      @page_title = ::I18n.t('page.title', term: @page.title)
      @meta_description = @page.meta_desc
      @current_menu_item = 'articles'
    else
      # Страницу нашли, но язык не тот, поэтому пытаемся отправить
      # пользователя на параллельную страницу с тем языком, который он искал
      @page = ::Page.find_by!(group_lang_id: @page.group_lang_id, lang: @content_lang)
      redirect_to my_page_link_to("/#{@page.path}")
    end
  end

  def about
    @page_title = I18n.t('about_site')
    @meta_description = I18n.t('about_site_description')
    @canonical_url = build_canonical_url('/about/')
  end
end
