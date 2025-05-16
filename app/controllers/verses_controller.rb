class VersesController < ApplicationController
  # https://github.com/rails/actionpack-page_caching
  caches_page :index, :chapter_ajax

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
      # ГЛАВНАЯ СТРАНИЦА

      # redirect_to "/#{I18n.locale}/#{current_bib_lang()}/gen/1/"

      # для работы переключателя языка
      @current_bib_lang = current_bib_lang()
      @locale_by_bib = locale_for_content_lang(@current_bib_lang)

      @page = ::Page.where(path_low: "links_#{@locale_by_bib.downcase}").first
      # @page = ::Page.find_by(path_low: "links_#{::I18n.locale}")
      if @page&.page_type.to_i == ::Page::PAGE_TYPES['список']
        @tree_menu = @page.tree_menu
      end

      # Первые три стиха из 1ИН, для главной страницы
      @main_verses = ::Verse.where(lang: @current_bib_lang, book: '1in', chapter: 1, :l.in => [1,2,3]).sort(line: 1).to_a

      @page_title = ::I18n.t('root_page.title')
      @meta_description = ::I18n.t('about_site_short')
      @canonical_url = "https://bibleox.com/#{I18n.locale}/"

      render 'main'
    else
      @content_lang = current_bib_lang()

      # Запрошен подстрочник
      @is_interliner = ['gr-ru', 'gr-en', 'gr-jp'].include?(@content_lang)
      if @is_interliner
        @int_content_lang =
        if @content_lang == 'gr-ru'
          'ru'
        elsif @content_lang == 'gr-en'
          'eng-nkjv'
        elsif @content_lang == 'gr-jp'
          'jp-ni'
        end
      end

      # не индексировать, где текст UI не совпадает с текстом контента
      if locale_for_content_lang(@content_lang) != ::I18n.locale.to_s
        @no_index = true
      end
      # не индексировать переводы: csl-pnm, en-nrsv
      if ::BIB_LANGS_NOT_INDEXED.include?(@content_lang)
        @no_index = true
      end

      @book_code ||= params[:book_code] || 'gen'
      @chapter = (params[:chapter] || 1).to_i

      # # ключ для кэширования
      @bible_path = "#{@content_lang}--#{@book_code}--#{@chapter}"

      # if stale?(last_modified: ::Time.now.beginning_of_week.utc, etag: @bible_path)
        @is_psalm = @book_code == 'ps'

        # AUDIO
        audio_prefix = "/s/audio/bib/#{@content_lang}/"
        audio_file = "#{audio_prefix}#{@book_code}/#{@book_code}#{ @chapter }.mp3"
        if ::File.exist?("#{Rails.root}/public#{ audio_file }")
          # во view сохраним только префикс, а ссылку будем собирать при запуске аудио
          @prefix_for_audio_link = audio_prefix
        end

        # cache doc: https://www.mongodb.com/docs/mongoid/master/reference/queries/#query-cache
        @verses = ::Verse.where(lang: @int_content_lang || @content_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a
        # Статьи-комментарии к стихам
        page_comments = ::Page.comments_for_verses(@verses)
        # индексируем по номерам стихов для быстрого доступа
        @comments = page_comments.map { [_1.path_low.split(':').last.to_i, _1] }.to_h

        # Запрошен подстрочник
        if @is_interliner
          # Раньше было так:
          # @dict = preload_dict_for_verses(@verses)

          # Теперь переделал полностью всё
          # 1. Надо отобразить сначалу строчку из нормального перевода.
          # 2. Потом греческие слова с подстрочным переводом.
          @verses_gr = ::Verse.where(lang: 'gr-ru', book: @book_code, chapter: @chapter).sort(line: 1).to_a
        end

        @current_menu_item = 'biblia'
        @page_title =
          ::I18n.t("books.mid.#{@book_code}") +
          ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
          " #{@chapter} / " +
          ::I18n.t('bible')

        # чтобы поисковики не жаловались на одинаковые заголовки в разных русских языках
        @page_title += " / ЦСЯ" if ['csl-ru', 'csl-pnm'].include?(@content_lang)

        @meta_description = ::I18n.t("books.full.#{@book_code}")
        @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")

        # ХЛЕБНЫЕ КРОШКИ
        @breadcrumbs = [::I18n.t('breadcrumbs.bible')]
        if ::BOOKS[@book_code][:zavet] == 1
          @breadcrumbs.push(::I18n.t('breadcrumbs.VZ'))
          @breadcrumbs.push(::I18n.t("breadcrumbs.bib_langs.vz.#{@content_lang}"))
        else
          @breadcrumbs.push(::I18n.t('breadcrumbs.NZ'))
          @breadcrumbs.push(::I18n.t("breadcrumbs.bib_langs.nz.#{@content_lang}"))
        end

        # META-description
        if @verses.any?
          @meta_description += ': ' + @verses.first(4).pluck(:text).join(' ')[0..200]
        end
        @meta_book_tags = [*@breadcrumbs, ::I18n.t("books.mid.#{@book_code}")]

        respond_to do |format|
          format.html { render 'index' }
        end
      # end
    end
  end

  def chapter_ajax
    # TODO: в процессе апдейта надо ещё тэг title у страницы поменять
    @content_lang = current_bib_lang()

    # Запрошен подстрочник
    @is_interliner = ['gr-ru', 'gr-en', 'gr-jp'].include?(@content_lang)
    if @is_interliner
      @int_content_lang =
      if @content_lang == 'gr-ru'
        'ru'
      elsif @content_lang == 'gr-en'
        'eng-nkjv'
      elsif @content_lang == 'gr-jp'
        'jp-ni'
      end
    end

    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    # # ключ для кэширования
    @bible_path = "#{@content_lang}--#{@book_code}--#{@chapter}"

    # if stale?(last_modified: ::Time.now.beginning_of_week.utc, etag: @bible_path)
      @is_psalm = @book_code == 'ps'

      # cache doc: https://www.mongodb.com/docs/mongoid/master/reference/queries/#query-cache
      @verses = ::Verse.where(lang: @int_content_lang || @content_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a
      # Статьи-комментарии к стихам
      page_comments = ::Page.comments_for_verses(@verses)
      # индексируем по номерам стихов для быстрого доступа
      @comments = page_comments.map { [_1.path_low.split(':').last.to_i, _1] }.to_h


      # Запрошен подстрочник
      if @is_interliner
        # Раньше было так:
        # @dict = preload_dict_for_verses(@verses)

        # Теперь переделал полностью всё
        # 1. Надо отобразить сначалу строчку из нормального перевода.
        # 2. Потом греческие слова с подстрочным переводом.
        @verses_gr = ::Verse.where(lang: 'gr-ru', book: @book_code, chapter: @chapter).sort(line: 1).to_a
      end


      @current_menu_item = 'biblia'
      @page_title =
        ::I18n.t("books.mid.#{@book_code}") +
        ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
        " #{@chapter} / " +
        ::I18n.t('bible')

      # чтобы поисковики не жаловались на одинаковые заголовки в разных русских языках
      @page_title += " / ЦСЯ" if ['csl-ru', 'csl-pnm'].include?(@content_lang)

      @breadcrumbs = [::I18n.t('breadcrumbs.bible')]
      if @verses.first.z == 1
        @breadcrumbs.push(::I18n.t('breadcrumbs.VZ'))
      else
        @breadcrumbs.push(::I18n.t('breadcrumbs.NZ'))
      end

      render 'chapter_ajax', layout: false
    # end
  end

  def quotes
    @current_menu_item = 'quotes'
    # @page_title = ::I18n.t("quotes")
  end

  def search
    # default
    @search_accuracy = params[:acc] || 'similar'
    @search_lang = params[:l] || ::LOCALE_TO_BIB_LANG[::I18n.locale.to_s]
    @search_books = params[:book]
    # не индексировать
    @no_index = true

    posibleAddr = params[:t].to_s
    # Сначала пробуем перевести: быт 1 1 -> быт 1:1
    # этот алгоритм нужен только тут, а метод human_to_link универсальный, используется везде
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

    @current_menu_item = 'biblia'
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

  # # Построение словаря для подстановки перевода в текст на лету
  # # {lexema => translation}
  # def preload_dict_for_verses verses
  #   words = verses.map { |v| v.data['w'] }.flatten.compact.sort.uniq
  #   words = words.map { |w| w.unicode_normalize(:nfd).downcase.strip }
  #   return {} if words.blank?

  #   words_clean = words.map { |w| ::DictWord.word_clean_gr(w).to_s }.uniq.sort

  #   # ЛЕКСЕМЫ И ТРАНСЛИТ для страницы

  #   lexemas = ::Lexema.where(:word.in => words_clean).pluck(:word, :lexema_clean, :transcription)
  #   # {word => lexema}
  #   w_lexemas = lexemas.map {|(w,l,t)| [w, l] }.to_h
  #   # {word => transcription}
  #   dict_transcriptions = lexemas.map {|(w,l,t)| [w, t] }.to_h

  #   # ПЕРЕВОД ЛЕКСЕМ и СЛОВ со страницы
  #   # -------------------------------
  #   words_and_lexemas = (w_lexemas.values + words_clean).compact.uniq

  #   r={
  #     dict: build_dict(words),
  #     dict_simple: build_dict_simple(words, words_and_lexemas, w_lexemas),
  #     dict_simple_no_endings: build_dict_simple_no_endings(words_and_lexemas),
  #     dict_transcriptions: dict_transcriptions,
  #   }
  #   # r.each { |k,v| puts(k); puts(v); puts }
  #   r
  # end

  # def build_dict words
  #   dicts = ::DictWord.where(:word.in => words).pluck(
  #     :word, :translation_short, :dict
  #   )

  #   # Вейсман
  #   w_dicts = {}
  #   # Дворецкий
  #   d_dicts = {}
  #   # Другие словари
  #   all_dicts = {}

  #   # в этих словарях перевод для слов и лексем
  #   dicts.each do |(word,transl,dict)|
  #     next unless transl.present?

  #     if dict == 'w'
  #       w_dicts[word] = transl
  #     elsif dict == 'd'
  #       d_dicts[word] = transl
  #     else
  #       all_dicts[word] = transl
  #     end
  #   end

  #   result = {}
  #   words.each do |w|
  #     # перевод слова или лексемы (приоритет: Вейсман, Дворецкий, прочие словари)
  #     transl = w_dicts[w] || d_dicts[w] || all_dicts[w]
  #     # перевод записываем в dict (ключ - просто w, без downcase, так как так будут искать во view)
  #     result[w] = transl if transl
  #   end
  #   result
  # end

  # def build_dict_simple words, words_and_lexemas, w_lexemas
  #   # подготовим также запасной словарик для поиска по упрощённому слову
  #   words_simple = words_and_lexemas.map do |w|
  #     ::DictWord.word_clean_gr(w)
  #   end

  #   # ищем в словаре по simple-полю
  #   dicts_simple =
  #   ::DictWord.where(:word_simple.in => words_simple).pluck(
  #     :word_simple, :translation_short, :dict
  #   )

  #   # Вейсман
  #   w_dicts = {}
  #   # Дворецкий
  #   d_dicts = {}
  #   # Другие словари
  #   all_dicts = {}

  #   # в этих словарях перевод для слов и лексем
  #   dicts_simple.each do |(word_simple,transl,dict)|
  #     next unless transl.present?

  #     if dict == 'w'
  #       w_dicts[word_simple] = transl
  #     elsif dict == 'd'
  #       d_dicts[word_simple] = transl
  #     else
  #       all_dicts[word_simple] = transl
  #     end
  #   end

  #   result = {}
  #   words.each do |w|
  #     _w = ::DictWord.word_clean_gr(w)
  #     # лексема слова
  #     l = w_lexemas[_w]
  #     # перевод слова или лексемы (приоритет: Вейсман, Дворецкий, прочие словари)
  #     transl = w_dicts[_w] || d_dicts[_w] || all_dicts[_w] || w_dicts[l] || d_dicts[l] || all_dicts[l]
  #     # перевод записываем в dict (ключ - просто w, без downcase, так как так будут искать во view)
  #     result[_w] = transl if transl
  #   end
  #   result
  # end

  # def build_dict_simple_no_endings words_and_lexemas
  #   # подготовим также запасной словарик для подбора соответствия без учёта окончаний
  #   # убираем кокончания у искомых слов
  #   words_simple_no_endings = words_and_lexemas.map do |w|
  #     _w = ::DictWord.word_clean_gr(w)
  #     _w = ::DictWord.remove_greek_ending(_w)
  #     _w
  #   end

  #   # ищем в словаре без окончаний
  #   dicts_simple_no_endings =
  #   ::DictWord.where(:word_simple_no_endings.in => words_simple_no_endings).pluck(
  #     :word_simple, :word_simple_no_endings, :translation_short, :dict
  #   )
  #   # Вайсман
  #   w_dicts = {}
  #   # Дворецкий
  #   d_dicts = {}
  #   # Другие словари
  #   all_dicts = {}

  #   # в этих словарях перевод для слов и лексем
  #   dicts_simple_no_endings.each do |(word,word_simple_no_endings,transl,dict)|
  #     next unless transl.present?

  #     if dict == 'w'
  #       w_dicts[word_simple_no_endings] = [transl,word]
  #     elsif dict == 'd'
  #       d_dicts[word_simple_no_endings] = [transl,word]
  #     else
  #       all_dicts[word_simple_no_endings] = [transl,word]
  #     end
  #   end

  #   result = {}
  #   words_simple_no_endings.each do |w|
  #     # перевод слова без окончания (приоритет: Вейсман, Дворецкий, прочие словари)
  #     transl = w_dicts[w] || d_dicts[w] || all_dicts[w]
  #     # перевод записываем в dict (ключ - просто w, без downcase, так как так будут искать во view)
  #     result[w] = transl if transl && transl[0]
  #   end
  #   result
  # end
end
