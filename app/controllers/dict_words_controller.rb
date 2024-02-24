class DictWordsController < ApplicationController
  def word
    @page_title = ::I18n.t('dict_words.title', word: params[:word])
    @meta_description = @page_title

    @lexemas = ::Lexema.where(word: params[:word]).to_a
    @dict_words = ::DictWord.where(word_simple: params[:word]).to_a
  end
end
