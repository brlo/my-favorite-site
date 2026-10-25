# Загружает в DictWord статьи лексиконов STEPBible (см. StepLexicon), но только для слов подстрочника:
# заголовок статьи должен совпасть (без ударений) со словоформой или леммой из BibWord / Lexema.
# Словари as и lsj пересоздаются целиком, поэтому импорт можно повторять.
#
#   StepLexiconImporter.call('as' => ['TBESG ... .txt'], 'lsj' => ['TFLSJ 0-5624 ... .txt', 'TFLSJ extra ... .txt'])
#   -> {'as' => 5123, 'lsj' => 5011}   # сколько статей загружено
class StepLexiconImporter
  # В TFLSJ имена и слова, которых нет в LSJ, взяты из Abbott-Smith - они уже есть в словаре as
  NOT_IN_LSJ = /LSJ has no entry|Not in LSJ/

  def self.call(files_by_dict, words: nil) = new(files_by_dict, words:).perform

  def initialize(files_by_dict, words: nil)
    @files_by_dict = files_by_dict
    @words = words
  end

  def perform
    entries = @files_by_dict.to_h { |dict, paths| [dict, collect(dict, paths)] }

    ::DictWord.transaction do
      ::DictWord.where(dict: entries.keys).delete_all
      entries.each { |dict, list| list.each { ::DictWord.create!(dict:, **_1) } }
    end
    entries.transform_values(&:size)
  end

  # word_simple всех слов подстрочника и их других написаний
  def needed_words
    @needed_words ||= begin
      words = @words || (::BibWord.pluck(:word, :lexema) + ::Lexema.pluck(:word, :lexema_clean)).flatten
      words.filter_map { ::DictWord.word_clean_gr(_1) }.uniq.flat_map { ::DictWord.spelling_variants(_1) }.to_set
    end
  end

  private

  # Строки разных номеров Стронга с одним заголовком (φυλακή G5438G/G5438H) склеиваем в одну статью
  def collect(dict, paths)
    rows = paths.flat_map { ::StepLexicon.each_row(_1).to_a }
    rows = rows.select { |row| row[:forms].any? { needed_words.include?(::DictWord.word_clean_gr(_1)) } }
    rows = rows.reject { NOT_IN_LSJ.match?(_1[:html]) } if dict == 'lsj'

    rows.group_by { _1[:forms].first }.map do |word, group|
      {
        word:              word,
        transcription_lat: group.filter_map { _1[:translit] }.first,
        translation_short: merge_glosses(group.filter_map { _1[:gloss] }),
        tag:               group.map { _1[:strong] }.uniq.join(' '),
        desc:              group.map { ::StepLexicon.convert_html(_1[:html]) }.uniq.join('<hr>'),
      }
    end
  end

  # "prison/watch: prison" + "prison/watch: watch" -> "prison/watch: prison, watch"
  def merge_glosses(glosses)
    glosses = glosses.uniq
    general = glosses.map { _1.split(':', 2).first.strip }.uniq
    return glosses.join('; ') unless general.size == 1 && glosses.all? { _1.include?(':') }

    "#{general.first}: #{glosses.map { _1.split(':', 2).last.strip }.uniq.join(', ')}"
  end
end
