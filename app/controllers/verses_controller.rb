class VersesController < ApplicationController
  def index
    if params[:book_code].blank? || params[:chapter].blank?
      redirect_to "/#{I18n.locale}/gen/1/"
    else
      @book_code ||= params[:book_code] || 'gen'
      @chapter = (params[:chapter] || 1).to_i

      @is_psalm = @book_code == 'ps'

      # аудио-файл для прослушивания текста
      audio_prefix = '/s/audio/bib/'
      audio_file = "#{audio_prefix}#{@book_code}/#{@book_code}#{ @chapter }.mp3"
      if ::File.exists?("#{Rails.root}/public/#{ audio_file }")
        # во view сохраним только префикс, а ссылку будем собирать при запуске аудио
        @prefix_for_audio_link = audio_prefix
      end

      @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

      @current_menu_item = 'biblia'
      @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'
      @page_title =
        ::I18n.t("books.mid.#{@book_code}") +
        ", #{ @is_psalm ? I18n.t('psalm') : I18n.t('chapter') }" +
        " #{@chapter} / " +
        ::I18n.t('bible')
      @meta_description = ::I18n.t("books.full.#{@book_code}")
      @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")
      @breadcrumbs = [::I18n.t('tags.bible')]
      if ::BOOKS[@book_code][:zavet] == 1
        @breadcrumbs.push(::I18n.t('tags.VZ'))
      else
        @breadcrumbs.push(::I18n.t('tags.NZ'))
      end
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
    @book_code ||= params[:book_code] || 'gen'
    @chapter = (params[:chapter] || 1).to_i

    @is_psalm = @book_code == 'ps'

    @verses = ::Verse.where(lang: current_lang, book: @book_code, chapter: @chapter).sort(line: 1).to_a

    @current_menu_item = 'biblia'
    @text_direction = current_lang == 'heb-osm' ? 'rtl' : 'ltr'
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

    posibleAddr = params[:t].to_s
    # Сначала пробуем перевести: быт 1 1 -> быт 1:1
    # этот алгоритм нужен только тут, а метод human_to_link универсальный, исползьуется везде
    if posibleAddr =~ /[\d]+\s[\d\-,]+$/
      posibleAddr = posibleAddr.sub(/([\d]+)\s([\d\-,]+)$/, '\1:\2')
    end

    # если это ссылка, то просто найдём её
    if link = ::AddressConverter.human_to_link(posibleAddr)
      redirect_to(link)
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

      @verses_json = ::VerseSearch.new(search_params).fetch_objects(5_000)
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
    redirect_to "/#{I18n.locale}/#{params[:book_code]}/#{params[:chapter]}/", status: 301
  end

  # Redirect: /ru/f/Дан. 1:2 -> /dan/1/#L2
  def goto_verse_by_human_address
    human_address = params[:human_address]
    redirect_to(::AddressConverter.human_to_link(human_address) || '/' )
  end
end
