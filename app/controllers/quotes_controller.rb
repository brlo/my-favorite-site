class QuotesController < ApplicationController
  def index
    @page_title = ::I18n.t('quotes_page.title') #'Избранные цитаты'
    @current_menu_item = 'quotes'

    @tree_data = ::QuotesSubject.tree_data
  end

  def show
    @subject_name = params[:page_path]
    @page = QuotesPage.find_by(path: params[:page_path])

    @current_menu_item = 'quotes'
    @page_title = ::I18n.t('quote_page.title', term: @subject_name)

    # @current_menu_item = 'quotes'
    # @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'
    @meta_description = "" #@subject.send("desc")

    @canonical_url = build_canonical_url("/q/#{ params[:page_path] }") # ???

    # @breadcrumbs = [::I18n.t('tags.bible')]
    # if ::BOOKS[@book_code][:zavet] == 1
    #   @breadcrumbs.push(::I18n.t('tags.VZ'))
    # else
    #   @breadcrumbs.push(::I18n.t('tags.NZ'))
    # end
    # if @verses.any?
    #   @meta_description += ': ' + @verses.first(4).pluck(:text).join(' ')[0..200]
    # end
    # @meta_book_tags = [*@breadcrumbs, ::I18n.t("books.mid.#{@book_code}")]
  end
end
