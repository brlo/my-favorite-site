module Tools
  module StringUtils
    class RomanToInt
      ROMAN = { 'I'=>1, 'V'=>5, 'X'=>10, 'L'=>50, 'C'=>100, 'D'=>500, 'M'=>1000 }
      LATIN_WORDS = { 'PRIMUS'=>1, 'PRIMUM'=>1, 'SECUNDUS'=>2, 'SECUNDUM'=>2, 'TERTIUS'=>3, 'TERTIUM'=>3, 'QUARTUS'=>4, 'QUARTUM'=>4  }

      def self.call(s)
        return LATIN_WORDS[s.upcase] if LATIN_WORDS[s.upcase]
        total = 0; prev = 0
        s.upcase.reverse.chars.each do |c|
          v = ROMAN[c] || 0
          v < prev ? total -= v : total += v
          prev = v
        end
        total > 0 ? total.to_s : nil
      end
    end
  end
end
