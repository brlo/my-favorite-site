class PagesController < ApplicationController
  def main
    redirect_to "/#{I18n.locale}/gen/1/"
  end

  def about
    @page_title = I18n.t('about_site')
    @meta_description = I18n.t('about_site_description')
    @canonical_url = build_canonical_url('/about/')
  end
end
