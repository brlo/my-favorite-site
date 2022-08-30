class VerseSearch
  attr_reader :params
  # params: {
  #   text: @search_text,
  #   book: @search_books,
  #   accuracy: @search_accuracy,
  #   lang: 'ru'
  # }
  def initialize params
    @params = params
  end

  def fetch_objects(count)
    text = params[:text].to_s.squeeze.strip
    book = params[:book]
    accuracy = params[:accuracy]
    lang = params[:lang]

    if params[:book].present?
      return [] unless ::BOOKS.has_key?(params[:book])
    end

    return [] unless lang == 'ru'

    search_params = {lang: lang}

    if accuracy == '1'
      # точное совпадение (пишем в кавычках)
      search_params['$text'] = {'$search' => "\"#{ text }\""}
    elsif accuracy == '2'
      # похожая фраза (когда будет готово отдельное поле, перейти на него)
      arr = text.gsub(/[^[[:alpha:]]]\s/, '').split(' ').first(5)
      regex = arr.map { |w| len = [2, w.length-3].max; w[0..len] }.join('[^\s]+\s')
      puts "=== regex: #{regex}"
      search_params['text'] = /#{regex}/i
    elsif accuracy == '3'
      # часть слова
      regex = text.split(' ').first.gsub(/[^[[:alpha:]]]/, '')
      search_params['text'] = /#{regex}/i
    end

    if book.present?
      if book == 'z1'
        search_params[:zavet] = 1
      elsif book == 'z2'
        search_params[:zavet] = 2
      else
        search_params[:book] = book
      end
    end

    # https://www.mongodb.com/docs/mongoid/master/reference/text-search/
    # https://www.mongodb.com/docs/manual/core/link-text-indexes/
    verses = ::Verse.where(
      **search_params
    ).limit(count).to_a
  end
end
