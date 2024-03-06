class DictWordsController < ApplicationController
  def word
    word = params[:word]

    # Если слово с какими-то диакритическими знаками, то редиректим на чистое слово
    @word_clean = ::DictWord.word_clean_gr(word)

    if @word_clean.blank?
      head 404
    end

    if word != @word_clean
      redirect_to "/#{I18n.locale}/words/#{@word_clean}"
    end

    @page_title = ::I18n.t('dict_words.title', word: word)
    @meta_description = @page_title

    @lexemas = ::Lexema.where(word: word).to_a
    lex_words = @lexemas.pluck(:lexema_clean).compact.uniq
    all_words = [word] + lex_words
    all_words.map! { |w| ::DictWord.word_clean_gr(w) }
    @dict_words = ::DictWord.where(:word_simple.in => all_words).to_a

    if @dict_words.blank?
      render status: 404
    end
  end
end
