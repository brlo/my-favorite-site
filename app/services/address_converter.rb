class AddressConverter

  # Переводит zah:1:1 -> Зах. 1:1
  def self.humanize address
    b, ch, l = address.to_s.split(':')
    book = ::I18n.t("books.short.#{b}")
    "#{book}. #{ch}:#{l}"
  end

  # Переводит Зах. 1:1,2-3,8 -> /zah/1/#L1,2-3,8
  def self.human_to_link address
    address = address.to_s.strip.downcase.gsub(/[\s\(\)]/, '')

    # адрес есть, > 3 символов, заканчивается цифрой
    if address.present? && address.length > 3 && address =~ /\d$/
      if address =~ /\:/
        # есть двоеточие, значит слева глава, а справа стихи
        book, ch, lines = address.scan(/^([\dI]{0,3}[А-ЯA-Z\.\-]{2,10})\s*(\d{1,3})\:([\d\-,]{1,20})$/i).first
      else
        # нет двоеточия, значит считаем, что указана только книга и глава
        book, ch = address.scan(/^([\dI]{0,3}[А-ЯA-Z\.\-]{2,10})\s*(\d{1,3}})$/i).first
      end

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
end
