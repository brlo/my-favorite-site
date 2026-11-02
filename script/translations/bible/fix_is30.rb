# Ис 30:6 в модуле NRKV обрезан после первого предложения: полный стих 개역개정 (bskorea.or.kr)
v = Verse.find_by!(tr_code: 'ko-nkrv', book: 'is', chapter: 30, line: 6)
t = '네겝 짐승들에 관한 경고라 사신들이 그들의 재물을 어린 나귀 등에 싣고 그들의 보물을 낙타 안장에 얹고 암사자와 수사자와 독사와 및 날아다니는 불뱀이 나오는 위험하고 곤고한 땅을 지나 자기에게 무익한 민족에게로 갔으나'
v.update!(text: t, text_search: t)
Verse.where(id: v.id).update_all("text_tsvector = to_tsvector('simple', text_search)")
puts v.reload.text
