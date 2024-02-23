class DictWordsController < ApplicationController
  def word
    @lexemas = ::Lexema.where(word: params[:word]).to_a
    @dict_words = ::DictWord.where(word: params[:word]).to_a
  end
end
