class VersesController < ApplicationController
  def index
    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i
    # @book_name = ::BOOKS[@book_code][:name]
    @book_name = ::I18n.t("books.short.#{@book_code}")

    @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).to_a
  end

  def search
    # https://www.mongodb.com/docs/manual/core/link-text-indexes/
    if params[:t].present?
      # из текста удаляем все символы, кроме пробела и A-ZА-Я0-9-,.
      @search_text = params[:t].gsub(/[^\sA-Za-zА-Яа-я0-9\-\,\.]*/, '')
      @search_accuracy = params[:acc]
      @search_books = params[:book]

      search_params = {
        text: @search_text,
        book: @search_books,
        accuracy: @search_accuracy,
        lang: current_lang
      }

      @verses = ::VerseSearch.new(search_params).fetch_objects(500)
      @matches_count = @verses.count
    else
      @search_text = params[:t]
      @search_accuracy = params[:acc]
      @search_books = params[:book]

      @verses = []
      @matches_count = 0
    end
  end
end
