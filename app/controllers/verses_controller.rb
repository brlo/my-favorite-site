class VersesController < ApplicationController
  def index
    @current_menu_item = 'biblia'
    @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'

    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    @is_psalm = @book_code == 'ps'

    @page_title =
      ::I18n.t("books.full.#{@book_code}") +
      ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
      " #{@chapter}"

    @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

    respond_to do |format|
      format.html { render 'index' }
    end
  end

  def chapter_ajax
    @current_menu_item = 'biblia'
    @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'

    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    @is_psalm = @book_code == 'ps'

    @page_title =
      ::I18n.t("books.full.#{@book_code}") +
      ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
      " #{@chapter}"

    @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

    render 'index', layout: false
  end

  def quotes
    @current_menu_item = 'quotes'
    # @page_title = ::I18n.t("quotes")
  end

  def search
    @current_menu_item = 'search'
    @page_title = ::I18n.t('search')

    # https://www.mongodb.com/docs/manual/core/link-text-indexes/
    if params[:t].present?
      # из текста удаляем все символы, кроме пробела и A-ZА-Я0-9-,.
      @search_text = params[:t].gsub(/[^\sA-Za-zА-Яа-я0-9\-\,\.\:\;]*/, '')
      @search_accuracy = params[:acc]
      @search_books = params[:book]

      @page_title += ": #{params[:t].to_s[0..20]}"

      search_params = {
        text: @search_text,
        book: @search_books,
        accuracy: @search_accuracy,
        lang: current_lang
      }

      @verses_json = ::VerseSearch.new(search_params).fetch_objects(500)
      @matches_count = @verses_json.count
    else
      @search_text = params[:t]
      @search_accuracy = params[:acc]
      @search_books = params[:book]

      @verses_json = []
      @matches_count = 0
    end
  end
end
