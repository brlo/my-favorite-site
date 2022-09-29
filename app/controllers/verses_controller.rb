class VersesController < ApplicationController
  def index
    if params[:book_code].blank? || params[:chapter].blank?
      redirect_to "/#{I18n.locale}/gen/1/"
    else
      @book_code ||= params[:book_code] || 'gen'
      @chapter = (params[:chapter] || 1).to_i

      @is_psalm = @book_code == 'ps'

      @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

      @current_menu_item = 'biblia'
      @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'
      @page_title =
        ::I18n.t("books.mid.#{@book_code}") +
        ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
        " #{@chapter}"
      @meta_description = @verses.find{|v| v.line == 1}.text[0..200]
      @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")

      respond_to do |format|
        format.html { render 'index' }
      end
    end
  end

  def chapter_ajax
    @current_menu_item = 'biblia'
    @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'

    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    @is_psalm = @book_code == 'ps'

    @page_title =
      ::I18n.t("books.mid.#{@book_code}") +
      ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
      " #{@chapter}"

    @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

    render 'chapter_ajax', layout: false
  end

  def quotes
    @current_menu_item = 'quotes'
    # @page_title = ::I18n.t("quotes")
  end

  def search
    # https://www.mongodb.com/docs/manual/core/link-text-indexes/
    if params[:t].present?
      # из текста удаляем все символы, кроме пробела и A-ZА-Я0-9-,.
      @search_text = params[:t].gsub(/[^\sA-ZА-ЯЁ0-9\-\,\.\:\;]*/i, '')
      @search_accuracy = params[:acc]
      @search_lang = params[:l]
      @search_books = params[:book]

      search_params = {
        text: @search_text,
        book: @search_books,
        accuracy: @search_accuracy,
        lang: @search_lang
      }

      @verses_json = ::VerseSearch.new(search_params).fetch_objects(5_000)
      @matches_count = @verses_json.count
    else
      @search_text = params[:t]
      @search_accuracy = params[:acc]
      @search_lang = params[:lang]
      @search_books = params[:book]

      @verses_json = []
      @matches_count = 0
    end

    @current_menu_item = 'search'
    @page_title = ::I18n.t('search_page.title')
    @page_title += ": #{params[:t].to_s[0..20]}" if params[:t].present?
    @meta_description = ::I18n.t('search_page.meta_description', search: @search_text, matches: @matches_count)
    if @verses_json.presence
      @meta_description +=
      ::I18n.t('search_page.meta_description_first_verse', verse: @verses_json.first['t'].to_s[0..150])
    end
    @canonical_url = build_canonical_url("/search/?acc=#{@search_accuracy}&l=#{@search_lang}&t=#{@search_text}")
  end

  def redirect_to_new_address
    redirect_to "/#{I18n.locale}/#{params[:book_code]}/#{params[:chapter]}/", status: 301
  end
end
