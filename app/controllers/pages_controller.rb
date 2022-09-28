class PagesController < ApplicationController
  def main
    redirect_to "/#{I18n.locale}/gen/1/"
  end

  def about
    @page_title = 'О сайте'
  end
end
