# json = [
#   {
#     "w": "Ἰούδας", "l": "Ἰούδας",
#     "tr": {"ru": "Иуда", "en": "Judas", "jp": "ユダ"},
#     "i": {"ch-r": "сущ.", "pd": "Им. п.", "r": "м.", "ch": "ед. ч."},
#     "zv": "Ioudas"
#   },
#   ...
# ]
# ::InterlinerCreator.add_interliner(book: 'iud', chapter: 1, start_line: 1, interliner_json_data: json)

class InterlinerCreator

  # Добавить подстрочную информацию от DeepSeek.
  # Используется только для построения подстрочного перевода.
  #
  # interliner_json_data = [
  #   {
  #     "w": "Ἰούδας",
  #     "l": "Ἰούδας",
  #     "tr": {"ru": "Иуда", "en": "Judas", "jp": "ユダ"},
  #     "i": {"ch-r": "сущ.", "pd": "Им. п.", "r": "м.", "ch": "ед. ч."},
  #     "zv": "Ioudas"
  #   },
  #   ...
  # ]
  def self.add_interliner book:, chapter:, start_line:, interliner_json_data:
    verses = ::Verse.where(lang: 'gr-ru', book: book, chapter: chapter).to_a

    # находим первую нужную нам строку
    verse = nil
    verses.size.times do
      # достаём первый элемент из массива (изменяя массив)
      verse = verses.shift
      break if verse.line == start_line
    end

    # Начинаем построение подстрочника с полной информацией verse.data['wi'],
    # вместо простых слов в verse.data['w'].

    # Мы будем по доставать по одному hash.
    # Наша конечная цель - полностью опустишить interliner_json_data
    #
    # нам вообще нужен бесконечный цикл, но на всякий случай делаем через times
    #
    # берём первое слово сначала (так будем делать и дальше)
    word_info_json = {}
    5.times {
      word_info_json = interliner_json_data.shift&.to_h&.stringify_keys
      break if ::DictWord.word_clean_diacritic_only_gr(word_info_json.to_h['w']).present?
    }

    # LOOP
    interliner_json_data.size.times do
      # выходим, если больше не осталось информации для подстрочника
      break if interliner_json_data.blank?
      # выходим, если в этой главе Библии больше не осталось стихов
      break if verse.nil?

      # Итак, у нас есть подходящий стих: verse,
      # есть первое слово с подробной информацией: word_info_json
      # Поехали!

      # ОСНОВНОЙ ЦИКЛ
      # перебираем слова из стиха, достраиваем для каждого слова подстрочную информацию.
      #
      # Обрабатываем массив со словами без информации, на их основе строим массив
      # из каждого слова hash, который содержит само слово и всю информацию по слову (перевод, транскрипция, морфология).
      words_with_info = []
      verse.data['w'].each do |w|
        _w = ::DictWord.word_clean_diacritic_only_gr(w)
        _wi = ::DictWord.word_clean_diacritic_only_gr(word_info_json['w'])
        # ИИ часто пишет вместо греческой буквы "ρ" латинскую "р": ὑπὲр. Из-за этого падаем. Поэтому делаем авто-замену буквы "р"
        # эта переменная только для проверок:
        _wi = _wi.to_s.tr('армкнvг', 'αρμκννγ')
        # поэтому правим и тут (слово и лексему), это будет сохраняться в БД
        word_info_json['w'] = word_info_json['w'].to_s.tr('армкнvг', 'αρμκννγ')
        word_info_json['l'] = word_info_json['l'].to_s.tr('армкнvг', 'αρμκννγ')

        # Если слова в стихе и слово от ИИ не равны (нарушена последовательность или ещё что-то)
        is_raise_or_skip = (_w != _wi)
        # исключение: иногда ИИ щаменяет 'δι᾿' на 'διὰ'. Это норм.
        is_raise_or_skip = false if (w == 'δι᾿' && word_info_json['w'] == 'διὰ')

        if is_raise_or_skip
          puts "!!!!!!!!!!!!!! #{_w} != #{_wi}"
          # знаки препинания (и "]·") пропускаем спокойно,
          # если в строке только символы из этого набора: "][.·,;", то ок.
          if (w.length <= 1) || (w.chars - "][.·,;".chars).empty?
            words_with_info << { raw: w }
            # next
          else
            # иначе падаем, чтобы не косячить
            raise("Wrong word! Not eq _w(#{w}) and _wi(#{word_info_json['w']})")
          end
        else
          # Раз дошли до сюда, значит слова совпадают. Продолжаем.
          bib_word = ::BibWord.add_word(
            word_info_json['w'], # тут самое правильное слово. Я просил ИИ оставить заглавные буквы только у названий и имен
            addr: verse.address, # "zah:14:21"
            lexema: word_info_json['l'], # lexema
            info: word_info_json['i'], # info: часть речи, падеж, число, род.
            translations: word_info_json['tr'], # подстрочный перевод
            transcriptions: {'en': word_info_json['zv']} # транскрипция
          )

          words_with_info << {
            raw: w, # слово, где сохранены большие буквы как было в тексте
            w: word_info_json['w'], # тут самое правильное слово. Я просил ИИ оставить заглавные буквы только у названий и имен
            bw_id: bib_word.id,
            lex: word_info_json['l'], # lexema
            inf: word_info_json['i'], # info: часть речи, падеж, число, род.
            trl: word_info_json['tr'].to_h.stringify_keys, # подстрочный перевод
            trc: {'en' => word_info_json['zv']} # транскрипция
          }

          # раз _w обработали, значит идём к следующему w, а значит надо взять и следующий word_info_json
          5.times {
            word_info_json = interliner_json_data.shift&.to_h&.stringify_keys
            break if ::DictWord.word_clean_diacritic_only_gr(word_info_json.to_h['w']).present?
          }
          # если их больше нет, то заканчиваем
          break if word_info_json.nil?
        end
      end

      # сохраняем полную информацию
      verse.data['wi'] = words_with_info
      verse.save
      words_with_info = nil

      # берём следующий стих из БД
      verse = verses.shift
    end
  end



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
