puts ::BOOKS.keys.join(" ")
refs = [["prit",3,[34]],["iak",4,[6]],["1pet",5,[5]],["mf",12,[33]],["1kor",6,[9,10]],["1kor",1,[18,20]],["1kor",4,[13]],["mf",18,[19,20]],["in",13,[20]],["mf",10,[40]],["mf",26,[7]],["ps",33,[9]],["ps",32,[9]],["ef",2,[20,21,22]],["ef",5,[2]],["1kor",3,[16]]]
%w[jp-ni cn-ccbs].each{|tr| refs.each{|b,c,vs| Verse.where(tr_code: tr, book: b, chapter: c, line: vs).order(:line).each{|v| puts "#{tr} #{b} #{c}:#{v.line} #{v.text}"}}}
