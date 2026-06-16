module Tools
  module String
    class Rubyfy
      # Пример использования:
      # ::Tools::String::Rubyfy.call("私[わたし]")
      # => <ruby><rb>私</rb><rt>わたし</rt></ruby>

      def self.call(text)
        return text unless text.present?

        text.gsub(/([\p{Han}]+)\[([\p{Hiragana}\p{Katakana}]+)\]/) do
          "<ruby><rb>#{$1}</rb><rt>#{$2}</rt></ruby>".html_safe
        end
      end
    end
  end
end
