m = Menu.find_by!(path: 'wvx9_О_стыдливости_De_Pudicitia', page_id: Page.find_by!(lang: 'ru', path: 'тертуллиан').id)
m.update!(title: m.title.sub('О стыдливости', 'О целомудрии')); puts m.title[0, 40]
