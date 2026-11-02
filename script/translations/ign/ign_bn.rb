%w[pr iak 1pet mf 1kor in ps ef gal rim 2kor].each{|b| puts [b, *%i[ja zh-Hans].map{|l| I18n.t("books.short.#{b}", locale: l, default: '-')}].join(" | ")}
puts BibleLinker.link_html("<p>（マタ 18:19；箴 3:34）</p>", "ja")
puts BibleLinker.link_html("<p>（太 18:19；箴 3:34）</p>", "zh-Hans")
