class DictWordsController < ApplicationController
  def word
    # раньше тут был поиск не по id, а по словам, поэтому какое-то время ещё надо слова поддерживать:
    param_id = params[:bib_word_id]

    if param_id.blank?
      # 1. Идентификатора нет - 404.
      head 404

    elsif param_id =~ /\d+/
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
      @dict_words = ::DictWord.where(:word_simple.in => all_words).to_a

      if @dict_words.blank?
        render status: 404
      end

    else
      # 1. Идентификатор - не цифра. Ищем это слово и редиректим на цифру (id).
      # редирект со слова на ID слова
      redicrect_from_word_to_word_id(param_id)
    end
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
