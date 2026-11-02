# 1 Тим 3:16 в модуле NRKV обрезан после первого предложения: восстанавливаем полный стих 개역개정
v = Verse.find_by!(tr_code: 'ko-nkrv', book: '1tim', chapter: 3, line: 16)
t = '크도다 경건의 비밀이여, 그렇지 않다 하는 이 없도다 그는 육신으로 나타난 바 되시고 영으로 의롭다 하심을 받으시고 천사들에게 보이시고 만국에서 전파되시고 세상에서 믿은 바 되시고 영광 가운데서 올려지셨느니라'
v.update!(text: t, text_search: t)
Verse.where(id: v.id).update_all("text_tsvector = to_tsvector('simple', text_search)")
puts v.reload.text
