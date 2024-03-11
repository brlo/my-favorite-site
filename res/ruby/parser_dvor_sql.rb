# ПАРСЕР СЛОВАРЯ ДВОРЕЦКОГО

# load 'res/ruby/parser_dvor.rb'
#
# DOC https://www.rubyguides.com/2012/01/parsing-html-in-ruby/
#
require 'open-uri'
require 'nokogiri'

dict = 'd'
word = ''
desc = ''

# Слова, которые стоит игнорировать. (Пока что обходимся без этого)
# ignore_ru = ['анат.', 'арам.', 'арх.', 'архит.', 'астр.', 'астрол.', 'атт.', 'беот.', 'бот.', 'бран.', 'вводн.', 'вм.', 'воен.', 'вост.', 'г.', 'грам.', 'греч.', 'дельф.', 'дор.', 'досл.', 'евр.', 'егип.', 'зап.', 'зоол.', 'ион.', 'ирон.', 'кирен.', 'кулин.', 'культ.', 'л.', 'лак.', 'лат.', 'лог.', 'макед.', 'мат.', 'мед.', 'миф.', 'мор.', 'муз.', 'новоатт.', 'о-в', 'оз.', 'охотн.', 'п-в', 'перс.', 'перен.', 'погов.', 'по друг.', 'поэт.', 'предполож.', 'презр.', 'р.', 'римск.', 'рит.', 'сев.', 'см.', 'сицил.', 'собир.', 'среднеатт. ', 'староатт. ', 'стих.', 'стяж.', 'с.-х.', 'т. е.', 'тж.', 'физиол.', 'филос.', 'шутл.', 'зол.', 'эп.', 'эп.-дор.', 'эп.-ион.', 'энкл.', 'южн.', 'юр.']

words_miss=[]
i=0
dict = 'd'
sanitizer = ::Rails::Html::SafeListSanitizer.new
ImportDict.all.each do |imp_dict_word|
  # Самое первое слово греческими буквами.
  # По-идее, в этом поле всегда должно быть только греческое слово. Вначале только идут определяния русских аббревиатур типа "атт."
  word_gr = imp_dict_word.topic.scan(/^\p{Greek}+/).first
  _desc = sanitizer.sanitize(imp_dict_word.definition.to_s, tags: [])
  # ищем самое первое слово (или слова) похожие на коротких перевод
  word_ru = _desc.scan(/\p{Cyrillic}[\(\)\p{Cyrillic}\s]+(?=[,\s\A$])/i).first
  if word_gr.present? && word_ru.present?
    word_gr = word_gr.to_s.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete('-').delete("\u0300-\u036F").strip.presence
    # В Библии есть такое слово?
    if Lexema.find_by(w: word_gr) || Lexema.find_by(lexema_clean: word_gr)
      # Это слово уже сохранено в словаре?
      d = ::DictWord.find_by(dict: dict, word_simple: word_gr, translation_short: word_ru)
      d_desc = DictWord.find_by(dict: dict, desc: _desc)
      if d.nil? || d_desc.nil?
        words_miss << [word_gr, word_ru]
        puts "============= id:#{imp_dict_word.id} #{imp_dict_word.topic} -- #{word_gr} -- #{word_ru} ==="
        ::DictWord.create!(
          dict: dict,
          word: word_gr,
          translation_short: word_ru,
          desc: _desc,
        )
        i+=1
        puts " ---------- #{ i } ----------"
      end
    end
  end
end; i # 2755 слов есть в словаре для Библии

# Удалить дубли (если что-то пошло не так)
# ds = DictWord.all.map { |d| DictWord.find_by(:id.ne => d.id, dict: d.dict, word: d.word, translation_short: d.translation_short) }.compact.map(&:destroy)




# File.readlines('db/dict_greek_russian_dvoretsky.ads').each do |line|
#   puts("--------------------------------")
#   puts(line)
#   html = Nokogiri::HTML5.fragment(line)
#   word_new_el = html.css('word').first
#   # попалось новое слово?
#   puts "word_new_el.present?: #{word_new_el.present?}"
#   if word_new_el.present?
#     puts "word_new_el.content: #{word_new_el.content}"
#     # старое уже было?
#     if word.present?
#       puts "CREATE!"
#       puts "word: #{word}"
#       puts "desc: #{desc}"
#       # удаляем какие-то странные $F0020 с пробелами по сторонам, если есть
#       desc = desc.gsub(/\s?\$F[0-9]+\s?/, '').strip
#       DictWord.create!(dict: dict, w: word, desc: desc)
#     end
#     word = word_new_el.content
#     desc = ""
#   else
#     desc += line.strip + "\n"
#   end
# end
