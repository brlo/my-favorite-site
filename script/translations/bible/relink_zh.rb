# Перелинковка статей zh-Hans со 思高 (cn-sb) на 和合本 上帝版 (cn-cuv).
#   - ссылка переводится на cn-cuv, только если все стихи адреса есть в 和合本
#     (второканон и дополнения Даниила остаются на 思高);
#   - видимое сокращение книги меняется с католического 思高 на протестантское 和合本;
#   - ссылки с нестандартным текстом и сноски с упоминанием 思高 идут в отчёт на ручную вычитку.
# По умолчанию только отчёт; APPLY=1 - применить.
#   YAML (источник правды):  bin/rails runner script/translations/bible/relink_zh.rb yaml
#   DB-only статьи:          bin/rails runner script/translations/bible/relink_zh.rb db
# Авторские страницы (Тихон, 祈祷文) не трогаются никогда.
require 'yaml'

# код книги сайта -> [сокращение 思高, сокращение 和合本]
ABBR = {
  'gen' => ['创', '创'], 'ish' => ['出', '出'], 'lev' => ['肋', '利'], 'chis' => ['户', '民'],
  'vtor' => ['申', '申'], 'nav' => ['苏', '书'], 'sud' => ['民', '士'], 'ruf' => ['卢', '得'],
  '1ts' => ['撒上', '撒上'], '2ts' => ['撒下', '撒下'], '3ts' => ['列上', '王上'], '4ts' => ['列下', '王下'],
  '1par' => ['编上', '代上'], '2par' => ['编下', '代下'], 'ezd' => ['厄上', '拉'], 'neem' => ['厄下', '尼'],
  'esf' => ['艾', '斯'], 'ps' => ['咏', '诗'], 'iov' => ['约', '伯'], 'pr' => ['箴', '箴'],
  'ekl' => ['训', '传'], 'pp' => ['歌', '歌'], 'is' => ['依', '赛'], 'ier' => ['耶', '耶'],
  'pier' => ['哀', '哀'], 'iez' => ['则', '结'], 'dan' => ['达', '但'], 'os' => ['欧', '何'],
  'iol' => ['岳', '珥'], 'am' => ['亚', '摩'], 'av' => ['北', '俄'], 'ion' => ['纳', '拿'],
  'mih' => ['米', '弥'], 'naum' => ['鸿', '鸿'], 'avm' => ['哈', '哈'], 'sof' => ['索', '番'],
  'ag' => ['盖', '该'], 'zah' => ['匝', '亚'], 'mal' => ['拉', '玛'],
  'mf' => ['玛', '太'], 'mk' => ['谷', '可'], 'lk' => ['路', '路'], 'in' => ['若', '约'],
  'act' => ['宗', '徒'], 'rim' => ['罗', '罗'], '1kor' => ['格前', '林前'], '2kor' => ['格后', '林后'],
  'gal' => ['迦', '加'], 'ef' => ['弗', '弗'], 'fil' => ['斐', '腓'], 'kol' => ['哥', '西'],
  '1sol' => ['得前', '帖前'], '2sol' => ['得后', '帖后'], '1tim' => ['弟前', '提前'], '2tim' => ['弟后', '提后'],
  'tit' => ['铎', '多'], 'fm' => ['费', '门'], 'evr' => ['希', '希'], 'iak' => ['雅', '雅'],
  '1pet' => ['伯前', '彼前'], '2pet' => ['伯后', '彼后'], '1in' => ['若一', '约壹'],
  '2in' => ['若二', '约贰'], '3in' => ['若三', '约叁'], 'iud' => ['犹', '犹'], 'otkr' => ['默', '启'],
}.freeze
# второканон: в 和合本 нет и не будет, ссылки остаются на 思高
# (tobit, iudf, prs, prsir, pos, var, 1-3mak, 2ezd, 3ezd - в ABBR не входят)

LINK_RE = %r{<a\s+href="((?:https://bibleox\.com)?/(?:zh-Hans|cn)/)cn-sb/([a-z0-9]+)/(\d+)/#(L[0-9,\-]+)">([^<]*)</a>}
STANDING = '圣经链接指向本站的思高本。'
AUTHOR_RE = /(祈祷文|吉洪|舍夫库诺夫)/

report = []
process_text = lambda do |text, where|
  text.gsub(LINK_RE) do
    host, code, ch, anchor, label = Regexp.last_match.captures
    unless ABBR[code]
      report << "#{where}: неизвестная книга #{code} (#{label}) - оставлено на 思高"
      next Regexp.last_match[0]
    end
    ranges = anchor.sub(/\AL/, '').split(',').map { _1.split('-').map(&:to_i) }
    missing = ranges.reject { |a, b| b ||= a; ::Verse.where(tr_code: 'cn-cuv', book: code, chapter: ch.to_i, line: a..b).count == b - a + 1 }
    unless missing.empty?
      report << "#{where}: #{label} -> #{anchor} нет в 和合本 - оставлено на 思高"
      next Regexp.last_match[0]
    end
    sigao, cuv = ABBR[code]
    new_label = if label.sub!(/\A#{Regexp.escape(sigao)}(?=[ \u00A0]?\d)/, cuv) || label.sub!(/\A#{Regexp.escape(sigao)}\z/, cuv)
      label
    else
      report << "#{where}: текст ссылки «#{label}» не начинается с #{sigao} - href изменён, текст вычитать"
      label
    end
    %(<a href="#{host.sub('/cn/', '/zh-Hans/')}cn-cuv/#{code}/#{ch}/##{anchor}">#{new_label}</a>)
  end
end

if ARGV[0] == 'yaml'
  files = ::Dir.glob(::Rails.root.join('db/translations/zh-Hans/ign_*.yml').to_s).sort
  files.each do |file|
    original = ::File.read(file)
    text = process_text.(original, ::File.basename(file))
    rest_sigao = text.include?('cn-sb/')
    text = text.gsub(STANDING, rest_sigao ? '圣经链接指向本站的和合本（上帝版）；次经书卷引思高本。' : '圣经链接指向本站的和合本（上帝版）。')
    next if text == original
    puts "yaml: #{::File.basename(file)}#{ENV['APPLY'] == '1' ? '' : ' (DRY RUN)'}"
    ::File.write(file, text) if ENV['APPLY'] == '1'
  end
elsif ARGV[0] == 'db'
  ::Page.where("body LIKE '%/cn-sb/%' OR \"references\" LIKE '%/cn-sb/%'").find_each do |page|
    next if AUTHOR_RE.match?(page.path)
    body = process_text.(page.body.to_s, "db:#{page.lang}:#{page.path}")
    refs = process_text.(page.references.to_s, "db:#{page.lang}:#{page.path}:references")
    rest_sigao = body.include?('cn-sb/') || refs.include?('cn-sb/')
    body = body.gsub(STANDING, rest_sigao ? '圣经链接指向本站的和合本（上帝版）；次经书卷引思高本。' : '圣经链接指向本站的和合本（上帝版）。')
    refs = refs.gsub(STANDING, rest_sigao ? '圣经链接指向本站的和合本（上帝版）；次经书卷引思高本。' : '圣经链接指向本站的和合本（上帝版）。')
    next if body == page.body && refs == page.references
    puts "db: #{page.lang}:#{page.path}#{ENV['APPLY'] == '1' ? '' : ' (DRY RUN)'}"
    next if ENV['APPLY'] != '1'
    page.update!(body: body, references: refs)
  end
else
  abort 'usage: relink_zh.rb yaml|db [APPLY=1]'
end

puts "--- отчёт (#{report.size}) ---"
report.each { puts _1 }
if ENV['APPLY'] == '1'
  ::File.write(::Rails.root.join('tmp/relink_zh_report.txt'), report.join("\n") + "\n") if report.any?
elsif report.any?
  abort '(DRY RUN - ничего не сохранено; APPLY=1 чтобы применить)'
end
