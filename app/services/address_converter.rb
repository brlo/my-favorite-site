class AddressConverter

  # ::AddressConverter.humanize("zah:1:1")
  # Переводит zah:1:1 -> Зах. 1:1
  def self.humanize address
    b, ch, l = address.to_s.split(':')
    book = ::I18n.t("books.short.#{b}")
    "#{book}. #{ch}:#{l}"
  end


  # ::AddressConverter.addr_to_link("zah:1:1")
  # Переводит zah:1:1 -> /zah/1/#L1
  def self.addr_to_link address
    book, ch, l = address.to_s.split(':')
    "/#{book}/#{ch}/#L#{l}"
  end

  # Текст из строки поиска -> ссылка на стих или nil.
  # Сначала пробуем перевести "быт 1 1" в "быт 1:1" (только для поиска, human_to_link универсален)
  # ::AddressConverter.search_text_to_link("Быт 1 1") # => "/gen/1/#L1"
  def self.search_text_to_link text
    # заменяем длинные тире на обычный дефис
    text = text.to_s.gsub(/[–—]/, '-')
    text = text.sub(/([\d]+)\s([\d\-,]+)$/, '\1:\2') if text =~ /[\d]+\s[\d\-,]+$/
    human_to_link(text)
  end

  # ::AddressConverter.human_to_link("Зах. 1:1,2-3,8")
  # Переводит Зах. 1:1,2-3,8 -> /zah/1/#L1,2-3,8
  # Переводит Зах. 1 -> /zah/1/
  # Понимает и названия книг на языках интерфейса: 约翰 3:16, 約翰 3:16, ヨハネ 3:16.
  def self.human_to_link address
    # NFKC приводит полноширинные цифры и двоеточие (３：１６) к обычным
    address = address.to_s.unicode_normalize(:nfkc).strip.downcase.gsub(/[ \s\(\)]/, '')
    # заменяем длинные тире на обычный дефис
    address = address.gsub(/[–—]/, '-')

    # адрес есть, > 3 символов, заканчивается цифрой
    if address.present? && address.length > 3 && address =~ /\d$/
      if address.include?(':')
        # есть двоеточие, значит слева глава, а справа стихи
        book, ch, lines = address.match(/\A(.+?)(\d{1,3}):([\d\-,]{1,20})\z/).to_a[1..3]
      else
        # нет двоеточия, значит считаем, что указана только книга и глава
        book, ch = address.match(/\A(.+?)(\d{1,3})\z/).to_a[1..3]
      end

      return nil unless book.present?

      # оставляем только буквы и цифры, убирая точки и дефисы
      book = book.gsub(/[^\p{L}\p{N}]/u, '')
      # находим наш код книги по человеческому названию
      book_code = BOOK_TO_CODE[book] || localized_book_code(book)

      # формируем ссылку
      if book_code
        str = "/#{book_code}/#{ch}/"
        str = str + "#L#{lines}" if lines
        str
      else
        # Название книги может само заканчиваться цифрой (ヨハネの手紙１).
        # Тогда обычный разбор съедает её как главу — ищем самое длинное известное название.
        link_by_known_book_prefix(address)
      end
    else
      nil
    end
  end

  # Короткие названия, которые люди реально набирают: 约翰, 約翰, ヨハネ.
  # Полные названия и books.short берутся из locale-файлов; здесь — обиходные формы.
  LOCALIZED_BOOK_ALIASES = {
    'ja' => {
      'ヨハネ' => 'in', 'マタイ' => 'mf', 'マルコ' => 'mk', 'ルカ' => 'lk',
      '使徒' => 'act', 'ローマ' => 'rim', 'ヘブライ' => 'evr', 'ヤコブ' => 'iak',
      'ユダ' => 'iud', '黙示録' => 'otkr', '創世記' => 'gen', '出エジプト' => 'ish',
      '詩篇' => 'ps', 'イザヤ' => 'is', 'エレミヤ' => 'ier', 'エゼキエル' => 'iez',
      'ダニエル' => 'dan',
    },
    'zh-Hans' => {
      '约翰' => 'in', '马太' => 'mf', '马可' => 'mk', '路加' => 'lk',
      '使徒' => 'act', '罗马' => 'rim', '希伯来' => 'evr', '雅各' => 'iak',
      '犹大' => 'iud', '启示录' => 'otkr', '创世记' => 'gen', '出埃及记' => 'ish',
      '诗篇' => 'ps', '以赛亚' => 'is', '耶利米' => 'ier', '以西结' => 'iez',
      '但以理' => 'dan',
    },
    'zh-Hant' => {
      '約翰' => 'in', '馬太' => 'mf', '馬可' => 'mk', '路加' => 'lk',
      '使徒' => 'act', '羅馬' => 'rim', '希伯來' => 'evr', '雅各' => 'iak',
      '猶大' => 'iud', '啟示錄' => 'otkr', '創世記' => 'gen', '出埃及記' => 'ish',
      '詩篇' => 'ps', '以賽亞' => 'is', '耶利米' => 'ier', '以西結' => 'iez',
      '但以理' => 'dan',
    },
  }.freeze

  # Ссылка по самому длинному известному названию книги в начале адреса.
  # Нужна для названий с цифрой на конце: ヨハネの手紙１ 3:16.
  def self.link_by_known_book_prefix address
    compact = address.gsub(/[^\p{L}\p{N}:,\-]/u, '')
    candidates = localized_book_map.map { |name, code| [name, code] }
    candidates += BOOK_TO_CODE.map { |name, code| [normalize_book_name(name), code] }
    candidates.sort_by { |name, _code| -name.length }.each do |name, code|
      next if name.blank? || !compact.start_with?(name)

      rest = compact[name.length..]
      if (match = rest.match(/\A(\d{1,3}):([\d\-,]{1,20})\z/))
        return "/#{code}/#{match[1]}/#L#{match[2]}"
      end
    end
    nil
  end

  # Названия книг на языках, для которых нет латиницы/кириллицы в BOOK_TO_CODE.
  # Карта строится из тех же locale-файлов, что и меню книг, поэтому не расходится с интерфейсом.
  def self.localized_book_code book
    localized_book_map[book]
  end

  def self.localized_book_map
    @localized_book_map ||= begin
      map = {}
      %w[ja zh-Hans zh-Hant].each do |locale|
        %w[mid short].each do |kind|
          translations = ::I18n.t("books.#{kind}", locale: locale, default: {})
          next unless translations.is_a?(Hash)

          translations.each do |code, name|
            normalized = normalize_book_name(name)
            map[normalized] ||= code.to_s if normalized.present?
          end
        end

        LOCALIZED_BOOK_ALIASES.fetch(locale, {}).each do |name, code|
          map[normalize_book_name(name)] ||= code
        end
      end
      map
    end
  end

  def self.normalize_book_name name
    name.to_s.unicode_normalize(:nfkc).downcase.gsub(/[^\p{L}\p{N}]/u, '')
  end

  # конвертация кодов книг из формата bibleox (optina) в формат azbyka:
  # ::AddressConverter.book_bibleox_to_azbyka('ish')
  # => 'Ex'
  def self.book_bibleox_to_azbyka book_code
    {
      'gen' => 'Gen',
      'ish' => 'Ex',
      'lev' => 'Lev',
      'chis' => 'Num',
      'vtor' => 'Deut',
      'nav' => 'Nav',
      'sud' => 'Judg',
      'ruf' => 'Rth',
      '1ts' => '1Sam',
      '2ts' => '2Sam',
      '3ts' => '1King',
      '4ts' => '2King',
      '1par' => '1Chron',
      '2par' => '2Chron',
      'ezd' => 'Ezr',
      'neem' => 'Nehem',
      '2ezd' => '2Ezr',
      'tov' => 'Tov',
      'iudf' => 'Judf',
      'esf' => 'Est',
      'pr' => 'Prov',
      'ekl' => 'Eccl',
      'pp' => 'Song',
      'prs' => 'Solom',
      'prsir' => 'Sir',
      'iov' => 'Job',
      'is' => 'Is',
      'ier' => 'Jer',
      'pier' => 'Lam',
      'pos' => 'pJer',
      'var' => 'Bar',
      'iez' => 'Ezek',
      'dan' => 'Dan',
      'os' => 'Hos',
      'iol' => 'Joel',
      'am' => 'Am',
      'av' => 'Avd',
      'ion' => 'Jona',
      'mih' => 'Mic',
      'naum' => 'Naum',
      'avm' => 'Habak',
      'sof' => 'Sofon',
      'ag' => 'Hag',
      'zah' => 'Zah',
      'mal' => 'Mal',
      '1mak' => '1Mac',
      '2mak' => '2Mac',
      '3mak' => '3Mac',
      '3ezd' => '3Ezr',
      'ps' => 'Ps',
      'mf' => 'Mt',
      'mk' => 'Mk',
      'lk' => 'Lk',
      'in' => 'Jn',
      'act' => 'Act',
      'iak' => 'Jac',
      '1pet' => '1Pet',
      '2pet' => '2Pet',
      '1in' => '1Jn',
      '2in' => '2Jn',
      '3in' => '3Jn',
      'iud' => 'Juda',
      'rim' => 'Rom',
      '1kor' => '1Cor',
      '2kor' => '2Cor',
      'gal' => 'Gal',
      'ef' => 'Eph',
      'fil' => 'Phil',
      'kol' => 'Col',
      '1sol' => '1Thes',
      '2sol' => '2Thes',
      '1tim' => '1Tim',
      '2tim' => '2Tim',
      'tit' => 'Tit',
      'fm' => 'Phlm',
      'evr' => 'Hebr',
      'otkr' => 'Apok'
    }[book_code]
  end
end
