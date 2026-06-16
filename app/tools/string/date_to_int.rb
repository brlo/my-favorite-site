module Tools
  module String
    class DateToInt
      # ::Tools::String::DateToInt.call('III век до н.э')
      ROMAN_CENTURIES = {
        'I' => 1, 'II' => 2, 'III' => 3, 'IV' => 4, 'V' => 5,
        'VI' => 6, 'VII' => 7, 'VIII' => 8, 'IX' => 9, 'X' => 10,
        'XI' => 11, 'XII' => 12, 'XIII' => 13, 'XIV' => 14, 'XV' => 15,
        'XVI' => 16, 'XVII' => 17, 'XVIII' => 18, 'XIX' => 19, 'XX' => 20,
        'XXI' => 21, 'XXII' => 22, 'XXIII' => 23, 'XXIV' => 24, 'XXV' => 25,
        'XXVI' => 26, 'XXVII' => 27, 'XXVIII' => 28, 'XXIX' => 29, 'XXX' => 30
      }

      def self.call(date_str)
        return if date_str.blank?

        str = date_str.to_s.strip
        sign = 1
        value = nil

        # Определяем знак (до н.э. или до Р.Х.)
        if str.match?(/(до\s*н\.?э\.?)|(до\s*р\.?х\.?)|BC|BCE|(π\.Χ)/i)
          sign = -1
        end

        # 1. Полная дата yyyy-mm-dd
        if str.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          value = str[0..3].to_i

        # 2. Год (цифры)
        elsif str =~ /\A~?\s*(\d{1,4})\z/
          value = $1.to_i

        # 3. Век (римские цифры + возможно "век"/"в." + до н.э.)
        elsif match = str.match(/([IVXLCDM]+)/)
          roman = match[1].upcase
          century_number = ROMAN_CENTURIES[roman]
          if century_number && century_number > 0
            # Примерный год в середине века
            value = (century_number - 1) * 100 + 50
          end
        end

        if value.present?
          sign * value
        end
      end
    end
  end
end
