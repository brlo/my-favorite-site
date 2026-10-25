class DictWordsController < ApplicationController
  skip_before_action :require_login_and_activation

  def word
    # раньше тут был поиск не по id, а по словам, поэтому какое-то время ещё надо слова поддерживать:
    param_id = params[:bib_word_id]

    if param_id.blank?
      # 1. Идентификатора нет - 404.
      head 404

    elsif param_id =~ /^\d+$/
      # СТАРЫЙ ДОСТУП К СЛОВАМ ПО DictWord.id
      # В параметрах id передаётся как 123

      # 1. Идентификатор - цифра. Ищем и отдаём по этому id слово.
      # @bib_word = ::BibWord.find(param_id) # ------------------------ раскомментировать после выпуска подстрочника, и привести в порядок view
      dict_word = ::DictWord.find(param_id) # а от этого отказаться в пользу bib_word (см. строку ниже с ---- комментарием)
      word = dict_word.word

      @page_title = ::I18n.t('dict_words.title', word: word)
      @meta_description = @page_title

      @lexemas = ::Lexema.where(word: word).to_a
      lex_words = @lexemas.pluck(:lexema_clean).compact.uniq
      # all_words = [@bib_word.word, @bib_word.lexema, word] + lex_words # ------------------------ раскомментировать после выпуска подстрочника, и привести в порядок view
      all_words = [dict_word.word, dict_word.lexema, word] + lex_words
      all_words.map! { |w| ::DictWord.word_clean_gr(w) }
      @dict_words = ::DictWord.where(word_simple: all_words).to_a

      if @dict_words.blank?
        render status: 404
      end

    elsif param_id =~ /bw\-\d+/
      # Новый доступ к словам по ссылке из подстрочника через BibWord.id
      # В параметрах id передаётся как bw-123

      param_id = param_id.gsub(/^bw\-/, '')
      # 1. Идентификатор - цифра. Ищем и отдаём по этому id слово.
      @bib_word = ::BibWord.find(param_id) # ------------------------ раскомментировать после выпуска подстрочника, и привести в порядок view
      # dict_word = ::DictWord.find(param_id) # а от этого отказаться в пользу bib_word (см. строку ниже с ---- комментарием)
      # word = dict_word.word
      word = @bib_word.word

      @page_title = ::I18n.t('dict_words.title', word: word)
      @meta_description = @page_title

      @lexemas = ::Lexema.where(word: word).to_a
      lex_words = @lexemas.pluck(:lexema_clean).compact.uniq
      all_words = [@bib_word.word, @bib_word.lexema, word] + lex_words # ------------------------ раскомментировать после выпуска подстрочника, и привести в порядок view
      # all_words = [dict_word.word, dict_word.lexema, word] + lex_words

      # русские словари - только в русской локали, английские словари STEPBible - во всех
      dicts = I18n.locale == :ru ? ::DictWord::DICTS.keys : ::DictWord::STEP_DICTS
      @dict_words = ::DictWord.lookup(all_words, dicts:)

      if @dict_words.blank?
        render status: 404
      end

    else
      # 1. Идентификатор - не цифра. Ищем это слово и редиректим на цифру (id).
      # редирект со слова на ID слова
      redicrect_from_word_to_word_id(param_id)
    end
  end

  # Все стихи, в которых встречается лексема (в любой форме): /ru/lexemas/λόγος
  def lexema
    @lexema = params[:lexema].to_s
    words = ::BibWord.where(lexema: @lexema).pluck(:word, :addrs)
    if words.empty?
      # в таблице lexemas лексема бывает записана с другими ударениями - сравниваем без диакритики
      clean = ::DictWord.word_clean_gr(@lexema)
      lexemas = ::BibWord.distinct.pluck(:lexema).compact.select { ::DictWord.word_clean_gr(_1) == clean }
      words = ::BibWord.where(lexema: lexemas).pluck(:word, :addrs) if clean && lexemas.any?
    end
    return head(404) if words.empty?

    @forms = words.map(&:first).uniq
    book_order = ::BOOKS.keys.each_with_index.to_h
    addrs = words.flat_map(&:last).uniq.sort_by do |addr|
      book, ch, line = addr.split(':')
      [book_order.fetch(book, book_order.size), ch.to_i, line.to_i]
    end
    @addrs = ::Kaminari.paginate_array(addrs).page(params[:page]).per(100)

    # греческий текст и перевод, который сейчас читает пользователь
    verses = ::Verse.where(address: @addrs.to_a, tr_code: ['gr-ru', helpers.current_bib_lang]).to_a
    @greek = verses.select { _1.tr_code == 'gr-ru' }.index_by(&:address)
    @translated = verses.reject { _1.tr_code == 'gr-ru' }.index_by(&:address)

    @page_title = ::I18n.t('bib_word_info.lexema_title', lexema: @lexema)
    @meta_description = @page_title
    @no_index = true if params[:page].to_i > 1
  end

  private

  # раньше был поиск не по id, а по словам, поэтому тут производим редирект на id
  def redicrect_from_word_to_word_id(word)
    word_clean = ::DictWord.word_clean_gr(word)

    lexemas = ::Lexema.where(word: word).to_a
    lex_words = lexemas.pluck(:lexema_clean).compact.uniq
    all_words = [word] + lex_words
    all_words.map! { |w| ::DictWord.word_clean_gr(w) }
    dict_word = ::DictWord.where(word_simple: all_words).first

    if dict_word
      redirect_to "/#{I18n.locale}/words/#{dict_word.id}"
    else
      head 404
    end
  end
end
