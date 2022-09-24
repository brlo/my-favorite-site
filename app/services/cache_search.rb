require 'json'

class CacheSearch
  SEARCH_TYPES = %w(exact similar partial)
  SEARCH_LANGS = %w(ru csl-pnm csl-ru eng-nkjv heb-osm gr-lxx-byz)

  class << self
    def get(term, search_type, lang)
      return unless term.present?
      return unless SEARCH_TYPES.include?(search_type)

      term = safe_term(term)
      filename = safe_filename(term)

      return unless term.present? && term.length > 2
      return unless filename.present?
      return unless SEARCH_LANGS.include?(lang)

      path_to_folder = "db/cache_search/#{search_type}/#{lang}"
      # создаём весь уровень каталогов
      FileUtils.mkdir_p(path_to_folder)
      filepath = "#{path_to_folder}/#{filename}.json"

      verses_json =
      # КЭШ
      if ::File.file?(filepath)
        # читаем, парсим, отдаём
        begin
          ::JSON.parse(::File.read(filepath)) || []
        rescue ::JSON::ParserError
          []
        end

      # НЕ КЭШ
      else
        # добываем данные из БД
        _verses_json = yield
        # сохраняем в файл
        ::File.open(filepath, 'w') { |f| f.write(::JSON.pretty_generate(_verses_json)) }

        # отдаём
        _verses_json
      end

      # Ответ в JSON-формате всегда
      verses_json
    end

    def safe_term(term)
      # пустоты заменяем на 1 пробел
      term = term.to_s.gsub(/[ \t\n\r]+/, ' ')
      # оставляем только очевидное: буквы, цифры, основные знаки пунктуации, пробел
      term = term.to_s.gsub(/[^\s[[:alpha:]]0-9\.\,\-\?\!]/i, '')
      # повторяющиеся знаки пунктуации убираем (особенно ".."),
      # чтобы не путешествовали по файловой системе
      term = term.to_s.gsub(/[\.\,\-\?\!]{2,}/, '')
      term = term.strip

      # больше 100 символов искать нельзя
      term = term[0..99]

      term.downcase
    end

    def safe_filename(term)
      # в имени файла всё, кроме букв, меняем на "_"
      term.gsub(/[^[[:alpha:]]]/i, '_')
    end
  end
end
