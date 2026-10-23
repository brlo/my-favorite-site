# В переведённых статьях раздела-списка (например, en-q) заменяет ссылки на страницы языка оригинала
# ссылками на их переводы, если переводы уже есть:
#   https://bibleox.com/ru/ru/w/Таинство-Священства -> https://bibleox.com/en/en/w/Xy12_The_Sacrament_of_Priesthood/
# Якорь из ссылки убираем: заголовки, а с ними и якоря, в переводе другие.
#
#   TranslationRelinker.call(lang: 'en', list: 'en-q') -> [сообщения]
class TranslationRelinker
  def self.call(**) = new(**).perform

  def initialize(lang:, list:, src_lang: 'ru', is_dry_run: false)
    @lang = lang
    @list = list
    @src_lang = src_lang
    @is_dry_run = is_dry_run
    # https://bibleox.com/ru/ru/w/путь/#якорь и старый вид https://bibleox.com/ru/q/путь
    @href_re = %r{href="(https?://bibleox\.com/[a-z]{2}(?:-[A-Za-z]+)?/(?:#{::Regexp.escape(src_lang)}/w|q)/([^"#?/]+)/?(#[^"]*)?)"}
  end

  def perform
    list = ::Page.find_by(path_low: @list.downcase, lang: @lang)
    return ["нет страницы-списка: #{@list}"] unless list

    ::Page.where(parent_id: list.id, lang: @lang).flat_map { relink_page(_1) }
  end

  private

  def relink_page(page)
    log = []
    changes = %w[body references].to_h do |field|
      html = page[field].to_s.gsub(@href_re) do |match|
        url, path = $1, ::CGI.unescape($2)
        target = translation_of(path)
        next match unless target

        log << "#{page.path}: #{url} -> #{target.path}"
        %(href="https://bibleox.com/#{@lang}/#{@lang}/w/#{target.path}/")
      end
      [field, html]
    end.select { |field, html| html != page[field].to_s }

    page.update!(changes) if changes.any? && !@is_dry_run
    log
  end

  def translation_of(path)
    @translations ||= {}
    return @translations[path] if @translations.key?(path)

    src = ::Page.find_by(lang: @src_lang, path_low: path.downcase)
    @translations[path] = src && ::Page.find_by(lang: @lang, group_lang_id: src.group_lang_id)
  end
end
