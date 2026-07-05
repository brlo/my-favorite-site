class TranslationProject < ApplicationRecord
  has_many :segments, dependent: :destroy
  has_many :translations, dependent: :destroy

  validates :title, presence: true

  def add_part(body:, lang:, part: nil)
    part = (self.segments.maximum(:part) || 0) + 1 if part.nil?

    # Парсим HTML контент страницы
    parser = ::HtmlSegmentParser.new(body, lang: lang)
    segments_data = parser.parse

    # в первой части вначале добавляем перевод названия труда (line: 0)
    create_title_segment(self.title, lang) if part == 1

    # Создаем сегменты
    create_segments_from_data(segments_data, part, lang)

    # Обновляем доступные языки
    # update_available_langs()
    part
  end

  def create_title_segment title, lang
    # заголовок создаётся в первой части, главе 0, линии 0
    segment = segments.new(
      part: 1,
      chapter: 0,
      paragraph: 0,
      line: 0,
      text: title,
      lang: lang,
      is_original: true,
      open_tags: [],
      close_tags: [],
      # document_id: id
    )
    segment.save!
  end

  def create_segments_from_data(segments_data, part, lang)
    chapter_counter = 1
    paragraph_counter = 1
    segment_counter = 1

    segments_data.each do |segment_data|
      # Если это заголовок, увеличиваем счетчик главы
      if segment_data[:open_tags].any? { |tag| tag[:n].start_with?('h') }
        chapter_counter += 1
        paragraph_counter = 1
      end

      # Если это новый параграф или блок, увеличиваем счетчик параграфа
      par_tags = ['p', 'blockquote', 'div']
      if segment_data[:open_tags].any? { |tag| par_tags.include?(tag[:n]) }
        paragraph_counter += 1
        segment_counter = 1
      end

      # Создаем сегмент
      segment = segments.new(
        part: part,
        chapter: chapter_counter,
        paragraph: paragraph_counter,
        line: segment_counter,
        text: segment_data[:text],
        lang: lang,
        is_original: true,
        open_tags: segment_data[:open_tags],
        close_tags: segment_data[:close_tags],
        # document_id: id
      )

      unless segment.save
        raise("Error while creating Segment: --- #{segment.inspect} --- #{segment.errors.messages}")
      end

      segment_counter += 1
    end
  end

  def result_for(part:, lang_to:)
    segments = self.segments
      .includes(:translations)
      .where(part: part)
      .order(:chapter, :paragraph, :line).to_a

    result_html = ''
    references_html = '<ol>'
    references_count = 0
    is_prev_skip = false

    segments.each do |segment|
      # находим переводы на нужный язык, выбираем лучшие
      ts = segment.translations.select { it.lang == lang_to }
      t = ts.find { it.is_approved? }
      t = ts.max_by { it.vote_score } if t.nil?
      if t.nil?
        result_html += '<br><...><br>' if is_prev_skip == false
        is_prev_skip = true
        next
      end
      is_prev_skip = false

      # обрамляем перевод тэгами из сегмента,
      # комментарий к переводу уносим в сноску
      result_html += segment.open_tags.map { "<#{it['n']}>" }.join
      result_html += t.text.to_s + ' '
      if t.sub_text.present?
        references_count += 1
        result_html += "[#{references_count}]"
        references_html += "<li>#{t.sub_text}</li>"
      end
      result_html += segment.close_tags.map { "</#{it['n']}>" }.join
    end
    references_html += '</ol>'

    [result_html, references_html]
  end

  # На сколько процентов завершён перевод
  def progress_for(part:, lang_to:)
    segments_ids = self.segments.where(part: part).ids
    total_segments = segments_ids.count
    translated_segments = self.translations.where(segment_id: segments_ids, lang: lang_to).count('distinct segment_id')

    progress_percent = total_segments.zero? ? 0 : (translated_segments * 100 / total_segments)
  end

  # На сколько процентов завершены переводы
  def progress_for_all_langs
    # Сколько сегментов переведено в каждом языке
    # {"ru" => 12}
    translations_count = self.translations.group(:lang).count('distinct segment_id')
    # сколько всего сегментов надо перевести
    total_segments = self.segments.count

    result = Hash.new(0)
    translations_count.each do |lang, translated_segments|
      result[lang] = translated_segments * 100 / total_segments
    end
    result
  end

  def title_for_lang lang
    title_segment = self.segments.find_by(part: 1, chapter: 0, paragraph: 0, line: 0)
    return if title_segment.nil?

    title_translations = title_segment.translations.where(lang: lang).to_a
    ::TranslationsService.sort_by_priority(title_translations)&.last&.text
  end

  # # Добавляет страницу и парсит её на сегменты
  # def add_page(page_body:, lang:, chapter: 1, paragraph: 1)
  #   parser = HtmlSegmentParser.new(page_body, lang: lang)
  #   segments_data = parser.parse

  #   current_chapter = chapter
  #   current_paragraph = paragraph

  #   segments_data.each do |data|
  #     # Обновляем счётчики при встрече структурных тегов
  #     if data[:open_tags].any? { |tag| tag[:n] =~ 'h2' }
  #       current_chapter += 1
  #       current_paragraph = 1
  #     elsif ['p', 'blockquote', 'div'].include?(data[:open_tags].last&.dig(:n))
  #       current_paragraph += 1
  #     end

  #     segments.create!(
  #       chapter: current_chapter,
  #       paragraph: current_paragraph,
  #       line: inline_segment?(data) ? rand(1..1000) : nil, # или логика определения inline
  #       lang:,
  #       text: data[:text],
  #       is_original: true,
  #       open_tags: data[:open_tags],
  #       close_tags: data[:close_tags]
  #     )
  #   end
  # end

  private

  def inline_segment?(data)
    # Простая эвристика: если нет блочных тегов в open_tags
    block_tags = %w[p blockquote div h1 h2 h3 h4 h5 h6 pre table]
    (data[:open_tags] & block_tags.map { |t| { n: t } }).empty?
  end
end
