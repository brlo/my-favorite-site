# Библейская история на 3D-глобусе: таймлайн событий от Шестоднева до Авраама.
# Вся логика на клиенте (app/javascript/bible_map), текстуры лежат в public/bible_map и отдаются с res.bibleox.com.
class BibleMapController < ApplicationController
  skip_before_action :require_login_and_activation

  def show
    @page_title = 'Библейская история на глобусе'
    @meta_description = 'Шестоднев, рай, потоп и путь Авраама на трёхмерном глобусе с таймлайном событий'
    @canonical_url = 'https://bibleox.com/ru/bible-map/'
    # тексты пока только на русском: остальные языки интерфейса ведут на ту же страницу, но не индексируются
    @no_index = ::I18n.locale != :ru
    render layout: false
  end
end
