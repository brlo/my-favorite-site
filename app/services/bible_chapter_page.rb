# Всё, что нужно для показа главы Библии: стихи, комментарии, карта цитирования,
# заголовок, описание, хлебные крошки. Контроллер только раскладывает это по переменным шаблона.
class BibleChapterPage
  # переводы-подстрочники: язык контента -> код перевода, из которого берём основной текст
  INTERLINEAR_TR_CODES = { 'gr-ru' => 'ru', 'gr-en' => 'eng-nkjv', 'gr-jp' => 'jp-ni' }.freeze

  attr_reader :content_lang, :book_code, :chapter, :ui_locale

  # content_lang - код перевода Библии (ru, eng-nkjv, gr-ru...), ui_locale - язык интерфейса
  def initialize(content_lang:, book_code:, chapter:, ui_locale:)
    @content_lang = content_lang
    @book_code = book_code
    @chapter = chapter.to_i
    @ui_locale = ui_locale.to_s
  end

  # Запрошен подстрочник
  def is_interliner?
    INTERLINEAR_TR_CODES.key?(content_lang)
  end

  # Из какого перевода берём основной текст при подстрочнике
  def interliner_tr_code
    INTERLINEAR_TR_CODES[content_lang]
  end

  def is_psalm?
    book_code == 'ps'
  end

  # Не индексировать, где текст UI не совпадает с текстом контента, и переводы csl-pnm, en-nrsv
  def no_index?
    content_locale != ui_locale || ::BIB_LANGS_NOT_INDEXED.include?(content_lang)
  end

  # ключ для кэширования
  def cache_key
    "#{content_lang}--#{book_code}--#{chapter}"
  end

  def audio_file
    file = "/s/audio/bib/#{content_lang}/#{book_code}/#{book_code}#{chapter}.mp3"
    file if ::File.exist?("#{Rails.root}/public#{file}")
  end

  def verses
    @verses ||= ::Verse.where(tr_code: interliner_tr_code || content_lang, book: book_code, chapter: chapter).order(line: :asc).to_a
  end

  # Для подстрочника: сначала строчка из нормального перевода, потом греческие слова с подстрочным переводом
  def verses_gr
    return unless is_interliner?
    @verses_gr ||= ::Verse.where(tr_code: 'gr-ru', book: book_code, chapter: chapter).order(line: :asc).to_a
  end

  # Статьи-комментарии к стихам, по номерам стихов
  def comments
    @comments ||= ::Page.comments_for_verses(verses).map { [_1.path_low.split(':').last.to_i, _1] }.to_h
  end

  # Карта цитирования: сколько раз стихи упоминаются в трудах святых отцов.
  # Показываем труды на том же языке, что и выбранный перевод Библии
  def cite_counts
    @cite_counts ||= ::BibleReference.verse_counts(book_code, chapter, content_locale)
  end

  def cite_max
    cite_counts.values.max.to_i
  end

  def cite_min
    cite_counts.values.min.to_i
  end

  def title
    t = ::I18n.t("books.mid.#{book_code}") +
        ", #{ is_psalm? ? ::I18n.t('psalm') : ::I18n.t('chapter') }" +
        " #{chapter} / " +
        ::I18n.t('bible')
    # чтобы поисковики не жаловались на одинаковые заголовки в разных русских языках
    t += " / ЦСЯ" if %w[csl-ru csl-pnm].include?(content_lang)
    t
  end

  def meta_description
    desc = ::I18n.t("books.full.#{book_code}")
    desc += ': ' + verses.first(4).pluck(:text).join(' ')[0..200] if verses.any?
    desc
  end

  def breadcrumbs
    @breadcrumbs ||= begin
      testament = ::BOOKS[book_code][:zavet] == 1 ? 'VZ' : 'NZ'
      [
        ::I18n.t('breadcrumbs.bible'),
        ::I18n.t("breadcrumbs.#{testament}"),
        ::I18n.t("breadcrumbs.bib_langs.#{testament.downcase}.#{content_lang}"),
      ]
    end
  end

  def meta_book_tags
    [*breadcrumbs, ::I18n.t("books.mid.#{book_code}")]
  end

  private

  def content_locale
    ::BIB_LANG_TO_LOCALE[content_lang]
  end
end
