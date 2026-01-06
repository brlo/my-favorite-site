class TranslationProject
  include Mongoid::Document

  field :title, type: String
  field :desc, as: :description, type: String

  # Доступные для исходные языки для перевода с них (заполняется по мере добавления переводов)
  field :sl, as: :source_langs, type: Array, default: []
  # присоединённые и распарсеные страницы (ids), ставшие источниками перевода
  field :page_ids, type: Array, default: []
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # Связи
  has_many :segments, dependent: :destroy

  # Индексы
  index({ updated_at: -1 })

  def add_page(page)
    # Парсим HTML контент страницы
    parser = ::HtmlSegmentParser.new(page.body, page.lang)
    segments_data = parser.parse

    # Создаем сегменты
    create_segments_from_data(segments_data, page)

    # Обновляем доступные языки
    # update_available_langs()
  end

  private

  def create_segments_from_data(segments_data, page)
    chapter_counter = 1
    paragraph_counter = 1
    segment_counter = 1

    segments_data.each do |segment_data|
      # Если это заголовок, увеличиваем счетчик главы
      if segment_data[:open_tags].any? { |tag| tag.start_with?('h') }
        chapter_counter += 1
        paragraph_counter = 1
      end

      # Если это новый параграф или блок, увеличиваем счетчик параграфа
      if ['p', 'blockquote', 'div'].any? { |tag| segment_data[:open_tags].include?(tag) }
        paragraph_counter += 1
        segment_counter = 1
      end

      # Создаем сегмент
      segment = segments.create!(
        chapter: chapter_counter,
        paragraph: paragraph_counter,
        line: segment_data[:is_inline] ? segment_counter : nil,
        text: segment_data[:text],
        lang: page.lang,
        original: true,
        open_tags: segment_data[:open_tags],
        close_tags: segment_data[:close_tags],
        document_id: id
      )

      segment_counter += 1 unless segment_data[:is_inline]
    end
  end

  # def update_available_langs
  #   langs = segments.distinct(:lang)
  #   update(available_langs: langs) if langs.any?
  # end
end
