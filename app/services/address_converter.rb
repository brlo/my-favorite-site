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

  # ::AddressConverter.human_to_link("Зах. 1:1,2-3,8")
  # Переводит Зах. 1:1,2-3,8 -> /zah/1/#L1,2-3,8
  # Переводит Зах. 1 -> /zah/1/
  def self.human_to_link address
    address = address.to_s.strip.downcase.gsub(/[ \s\(\)]/, '')
    # заменяем длинные тире на обычный дефис
    address = address.gsub(/[–—]/, '-')

    # адрес есть, > 3 символов, заканчивается цифрой
    if address.present? && address.length > 3 && address =~ /\d$/
      if address =~ /\:/
        # есть двоеточие, значит слева глава, а справа стихи
        book, ch, lines = address.scan(/^([\dI]{0,3}[А-ЯA-Z\.\-]{2,10})[ \s]*(\d{1,3})\:([\d\-,]{1,20})$/i).first
      else
        # нет двоеточия, значит считаем, что указана только книга и глава
        book, ch = address.scan(/^([\dI]{0,3}[А-ЯA-Z\.\-]{2,10})[ \s]*(\d{1,3})$/i).first
      end

      return nil unless book

      # оставляем только буквы и цифры, убирая точки
      book = book.gsub(/[^0-9A-ZА-Я]/i, '')
      # находим наш код книги по человеческому названию
      book_code = BOOK_TO_CODE[book]

      # формируем ссылку
      if book_code
        str = "/#{book_code}/#{ch}/"
        str = str + "#L#{lines}" if lines
        str
      else
        nil
      end
    else
      nil
    end
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
