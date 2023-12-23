class PagesController < ApplicationController
  def main
    redirect_to "/#{I18n.locale}/gen/1/"
  end

  def list
    path = params[:page_path].to_s
    @pages = ::Page.where(page_type: 4, published: true).limit(100).to_a
    @canonical_url = build_canonical_url("/w/")

    @page_title = ::I18n.t('page.main_title')
    @meta_description = ::I18n.t('page.main_meta_desc')
    @current_menu_item = 'articles'

    render :index
  end

  def show
    path = params[:page_path].to_s
    @page = Page.find_by!(path_low: path.downcase)
    @canonical_url = build_canonical_url("/w/#{@page.path}")

    if @page.path != path
      # перенаправляем на путь с правильным регистром
      redirect_to @canonical_url, status: :found # :status => :moved_permanently
    end

    if @page.page_type.to_i == ::Page::PAGE_TYPES['список']
      @tree_menu = @page.tree_menu
    end

    @page_title = ::I18n.t('page.title', term: @page.title)
    @meta_description = @page.meta_desc
    @current_menu_item = 'articles'
  end

  def about
    @page_title = I18n.t('about_site')
    @meta_description = I18n.t('about_site_description')
    @canonical_url = build_canonical_url('/about/')
  end
end
