class ApplicationController < ActionController::Base
  before_action :set_is_night_mode

  def set_is_night_mode
    @is_night_mode = cookies[:isNightMode] == "1"
  end

  def current_lang
    lang = cookies[:'b-lang']

    if ['ru', 'csl-pnm', 'csl-ru'].include?(lang)
      lang
    else
      'ru'
    end
  end
end
