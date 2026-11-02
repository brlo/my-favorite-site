require 'nokogiri'
def txt(html) = Nokogiri::HTML(html.to_s.gsub(/<h2>(.*?)<\/h2>/,"\n\n## \\1\n").gsub(/<\/p>/,"\n").gsub(/<li>/,"\n- ")).text.strip
g=Page.where("path LIKE ?", "ИгнАн%").pluck(:group_lang_id)
g.each do |gid|
  ru=Page.find_by(group_lang_id: gid, lang: 'ru'); key=ru.path.sub('ИгнАн_','')
  %w[grc ru en fr].each do |l|
    p=Page.find_by(group_lang_id: gid, lang: l) or next
    File.write("tmp/ign/#{key}_#{l}.txt", "# #{p.title} | #{p.path}\n\n#{txt(p.body)}\n\n=== REFERENCES\n#{txt(p.references)}\n")
  end
end
