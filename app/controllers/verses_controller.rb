class VersesController < ApplicationController
  def index_redirect
    path  = "/#{I18n.locale}/#{current_bib_lang()}"
    path += "/#{params[:book_code]}/#{params[:chapter]}/"
    path += "?#{request.query_string}" if request.query_string.present?
    redirect_to path, status: :found # :status => :moved_permanently
  end

  def q_redirect
    # использую вставку названия статьи через CGI.escape потому что иначе какой-то
    # глюк возникает, и rails думает, что я отправляю пользователя на другой сайт, хотя это не так.
    path  =
    if params[:page_path].present?
      "/#{I18n.locale}/#{I18n.locale}/w/#{CGI.escape(params[:page_path].to_s)}"
    else
      "/#{I18n.locale}/#{I18n.locale}/w/q/"
    end
    path += "?#{request.query_string}" if request.query_string.present?
    redirect_to path, status: :found # :status => :moved_permanently
  end

  def index
    if params[:book_code].blank? || params[:chapter].blank?
      redirect_to "/#{I18n.locale}/#{current_bib_lang()}/gen/1/"
    else
      @content_lang = current_bib_lang()

      # не индексировать, где текст UI не совпадает с текстом контента
      if locale_for_content_lang(@content_lang) != ::I18n.locale.to_s
        @no_index = true
      end

      @book_code ||= params[:book_code] || 'gen'
      @chapter = (params[:chapter] || 1).to_i

      @is_psalm = @book_code == 'ps'

      # AUDIO
      audio_prefix = "/s/audio/bib/#{@content_lang}/"
      audio_file = "#{audio_prefix}#{@book_code}/#{@book_code}#{ @chapter }.mp3"
      if ::File.exists?("#{Rails.root}/public#{ audio_file }")
        # во view сохраним только префикс, а ссылку будем собирать при запуске аудио
        @prefix_for_audio_link = audio_prefix
      end

      @verses = ::Verse.where(lang: @content_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a
      # TODO: найти также все статьи для этой главы и встроить ссылки рядом со стихами

      if @content_lang == 'gr-ru' # gr-lxx-byz
        @dict = preload_dict_for_verses(@verses)
      end

      @current_menu_item = 'biblia'
      @text_direction = ['heb-osm', 'arab-avd'].include?(@content_lang) ? 'rtl' : 'ltr'
      @page_title =
        ::I18n.t("books.mid.#{@book_code}") +
        ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
        " #{@chapter} / " +
        ::I18n.t('bible')
      @meta_description = ::I18n.t("books.full.#{@book_code}")
      @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")

      # ХЛЕБНЫЕ КРОШКИ
      @breadcrumbs = [::I18n.t('tags.bible')]
      if ::BOOKS[@book_code][:zavet] == 1
        @breadcrumbs.push(::I18n.t('tags.VZ'))
      else
        @breadcrumbs.push(::I18n.t('tags.NZ'))
      end

      # META-description
      if @verses.any?
        @meta_description += ': ' + @verses.first(4).pluck(:text).join(' ')[0..200]
      end
      @meta_book_tags = [*@breadcrumbs, ::I18n.t("books.mid.#{@book_code}")]

      respond_to do |format|
        format.html { render 'index' }
      end
    end
  end

  def chapter_ajax
    # TODO: в процессе апдейта надо ещё тэг title у страницы поменять
    @content_lang = current_bib_lang()
    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    @is_psalm = @book_code == 'ps'

    @verses = ::Verse.where(lang: @content_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

    if @content_lang == 'gr-ru' # gr-lxx-byz
      @dict = preload_dict_for_verses(@verses)
    end

    @current_menu_item = 'biblia'
    @text_direction = ['heb-osm', 'arab-avd'].include?(@content_lang) ? 'rtl' : 'ltr'
    @page_title =
      ::I18n.t("books.mid.#{@book_code}") +
      ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
      " #{@chapter}"
    @breadcrumbs = [::I18n.t('tags.bible')]
    if @verses.first.z == 1
      @breadcrumbs.push(::I18n.t('tags.VZ'))
    else
      @breadcrumbs.push(::I18n.t('tags.NZ'))
    end

    render 'chapter_ajax', layout: false
  end

  def quotes
    @current_menu_item = 'quotes'
    # @page_title = ::I18n.t("quotes")
  end

  def search
    # default
    @search_accuracy = params[:acc] || 'similar'
    @search_lang = params[:l] || (::I18n.locale == :ru ? 'ru' : 'eng-nkjv')
    @search_books = params[:book]
    # не индексировать
    @no_index = true

    posibleAddr = params[:t].to_s
    # Сначала пробуем перевести: быт 1 1 -> быт 1:1
    # этот алгоритм нужен только тут, а метод human_to_link универсальный, исползьуется везде
    if posibleAddr =~ /[\d]+\s[\d\-,]+$/
      posibleAddr = posibleAddr.sub(/([\d]+)\s([\d\-,]+)$/, '\1:\2')
    end

    # если это ссылка, то просто найдём её
    if link = ::AddressConverter.human_to_link(posibleAddr)
      redirect_to("/#{I18n.locale}/#{@search_lang}#{link}")
    # https://www.mongodb.com/docs/manual/core/link-text-indexes/
    elsif params[:t].present?
      # из текста удаляем все символы, кроме пробела и A-ZА-Я0-9-,.
      @search_text = params[:t].gsub(/[^\s[[:alpha:]]\-\,\.\:\;]*/i, '')

      search_params = {
        text: @search_text,
        book: @search_books,
        accuracy: @search_accuracy,
        lang: @search_lang
      }

      if @search_accuracy == 'similar'
        min_len = ::VerseSearch.min_len(@search_lang)
        @search_regexp = @search_text.split(' ').select{|w| w.length >= min_len}
      else
        @search_regexp = @search_text
      end

      # Запрашиваем результаты из БД
      @verses_json = ::VerseSearch.new(search_params).fetch_objects(3_000)

      @matches_count = @verses_json.count
    else
      @search_text = params[:t]

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
    @meta_book_tags = [params[:t]] if params[:t].present?
    @canonical_url = build_canonical_url("/search/?acc=#{@search_accuracy}&l=#{@search_lang}&t=#{@search_text}")
  end

  def redirect_to_new_address
    redirect_to "/#{I18n.locale}/#{current_bib_lang()}/#{params[:book_code]}/#{params[:chapter]}/", status: 301
  end

  # Redirect: /ru/f/Дан. 1:2 -> /ru/ru/dan/1/#L2
  def goto_verse_by_human_address
    human_address = params[:human_address]
    path = '/'

    if link = ::AddressConverter.human_to_link(human_address)
      path = "/#{I18n.locale}/#{current_bib_lang()}#{link}"
    end

    redirect_to(path)
  end

  private

  # Построение словаря для подстановки перевода в текст на лету
  # {lexema => translation}
  def preload_dict_for_verses verses
    words = verses.map { |v| v.data['w'] }.flatten.compact.sort.uniq
    return {} if words.blank?

    words_clean = words.map { |w| clean(w) }.uniq.sort

    # ЛЕКСЕМЫ И ТРАНСЛИТ для страницы

    lexemas = ::Lexema.where(:word.in => words_clean).pluck(:word, :lexema_clean, :transcription)
    # {word => lexema}
    w_lexemas = lexemas.map {|(w,l,t)| [w, l] }.to_h
    # {word => transcription}
    w_transcriptions = lexemas.map {|(w,l,t)| [w, t] }.to_h

    # ПЕРЕВОД ЛЕКСЕМ и СЛОВ со страницы

    words_and_lexemas = (w_lexemas.values + words_clean).compact.uniq
    dicts = ::DictWord.where(:word_simple.in => words_and_lexemas).pluck(:word_simple, :translation_short, :dict)

    # Вайсман
    w_dicts = {}
    # Дворецкий
    d_dicts = {}
    # Другие словари
    all_dicts = {}

    # в этих словарях перевод для слов и лексем
    dicts.each do |(word,trans,dict)|
      if dict == 'w'
        w_dicts[word] = trans
      elsif dict == 'd'
        d_dicts[word] = trans
      else
        rest_dicts[word] = trans
      end
    end

    result = {dict: {}, transcription: {}}
    words.each do |w|
      _w = clean(w)
      # лексема слова
      l = w_lexemas[_w]
      # перевод слова или лексемы (приоритет: Вейсман, Дворецкий, прочие словари)
      trans = w_dicts[_w] || d_dicts[_w] || all_dicts[_w] || w_dicts[l] || d_dicts[l] || all_dicts[l]
      # перевод записываем в dict (ключ - просто w, без downcase, так как так будут искать во view)
      result[:dict][w] = trans
      # транскрипция. Будет использована при отсутствии перевода
      result[:transcription][w] = w_transcriptions[_w]
    end

    result
  end

  # очищает слово от всех спец. знаков и греческих диакритических символов
  def clean(word)
    # require 'unicode_utils'
    # UnicodeUtils.nfkd("ἅπερ")
    word&.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
  end
end
