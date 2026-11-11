# Перетекстовка 4 цитат 思高 на формулировки 和合本 (ссылки после relink указывают на cn-cuv)
# + перенаведение Ис 7:16 -> 7:14 (сдвиг нумерации 思高 vs 和合本 в Ис 7).
# bin/rails runner script/translations/bible/fix_quotes_db.rb [APPLY=1]
FIXES = {
  'Ch2c_古代基督教教堂' => [
    ["“人群中有几个法利塞人对耶稣说：‘师傅，责斥你的门徒罢！’耶稣回答说：‘我告诉你们：<strong>这些人若不作声，石头就要喊叫了！</strong>’”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/19/#L39-40\">路 19:39-40</a>）",
     "“众人中有几个法利赛人对耶稣说：‘夫子，责备你的门徒吧！’耶稣说：‘我告诉你们，<strong>若是他们闭口不说，这些石头必要呼叫起来。</strong>’”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/19/#L39-40\">路 19:39-40</a>）"],
  ],
  'Lc4k_守斋饮食' => [
    ["“主回答她说：‘玛尔大，玛尔大！你为了许多事操心忙碌，其实需要的惟有一件。玛利亚选择了更好的一分，是不能从她夺去的。’”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/10/#L41-42\">路 10:41-42</a>）",
     "“耶稣回答说：‘马大！马大！你为许多的事思虑烦扰，但是不可少的只有一件；马利亚已经选择那上好的福分，是不能夺去的。’”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/10/#L41-42\">路 10:41-42</a>）"],
    ["“你们应当谨慎，免得你们的心为宴饮沉醉，及人生的挂虑所累时，那意想不到的日子临于你们”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/21/#L34\">路 21:34</a>）",
     "“你们要谨慎，恐怕因贪食、醉酒，并今生的思虑累住你们的心，那日子就如同网罗忽然临到你们”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/lk/21/#L34\">路 21:34</a>）"],
  ],
  'Ik1c_古代圣像集' => [
    ["“为此，吾主要亲自给你们一个征兆：看，<strong>有位贞女要怀孕生子</strong>，给他起名叫厄玛奴耳”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/is/7/#L16\">赛 7:16</a>）",
     "“因此，主自己要给你们一个兆头，<strong>必有童女怀孕生子</strong>，给他起名叫以马内利”（<a href=\"https://bibleox.com/zh-Hans/cn-cuv/is/7/#L14\">赛 7:14</a>）"],
  ],
}
applied = 0
FIXES.each do |path, pairs|
  page = ::Page.find_by!(path: path)
  new_body = page.body
  pairs.each do |old, new|
    count = new_body.scan(old).size
    raise "#{path}: фрагмент найден #{count} раз (ожидался 1): #{old[0, 60]}" unless count == 1
    new_body = new_body.sub(old, new)
    applied += 1
    puts "#{path}: 1 цитата перетекстована"
  end
  page.update!(body: new_body) if ENV['APPLY'] == '1'
end
puts "#{applied} правок#{ENV['APPLY'] == '1' ? '' : ' (DRY RUN - APPLY=1 чтобы применить)'}"
