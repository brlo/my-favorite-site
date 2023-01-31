class QuotesController < ApplicationController
  def index
    @page_title = ::I18n.t('quotes_page.title') #'Избранные цитаты'
    @current_menu_item = 'quotes'

    @tree_data = ::QuotesSubject.tree_data
  end

  # TODO: открывать по имени статьи в любом регистре, но редиректить на правильный регистр
  def show
    @page = QuotesPage.find_by(path: params[:page_path])

    @page_title = ::I18n.t('quote_page.title', term: @page.title)
    @meta_description = @page.meta_desc
    @canonical_url = build_canonical_url("/q/#{ params[:page_path] }")
    @current_menu_item = 'quotes'
  end
end
