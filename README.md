# BIBLEOX.COM

Запуск для разработки:

Перед запуском, если ты собираешь собирать Dockerfile впервые в маке, раскоментируй там правильную строку для мака, FROM --platform

docker compose up -d

Консольи разработчика:

docker exec -it bibleox bundle exec rails c

Деплой в прод через:

./bin/bib_deploy.sh

Или удалённый вход на сервер и там:

bib_update_code

bib_restart

* Ruby version

3.1+

* System dependencies

mongo-4.2

* Database initialization

```shell
# mkdir -p /srv/warehouse/mongo /etc/bibleox/config/mongo /var/log/mongo
# sudo touch /var/log/mongo/mongod.log
# sudo chmod 0777 -R /var/log/mongo
sudo docker run --name mongo-4.2 -p 27017:27017 \
  --memory=500m \
  --restart always \
  -v /srv/warehouse/mongodb:/data/db \
  -v /etc/bibleox/config/mongo/mongod.conf:/etc/mongod.conf \
  -v /var/log/mongo:/var/log/mongo \
  --log-opt max-size=1m --log-opt max-file=1 \
  -d brlo/mongo:4.2

# Для настройки доступа
sudo docker exec -it mongo-4.2 mongo admin

# создаём юзера, который занимается только управлением (у него нет доступа к базам на чтение запись, он только создаёт пользователей и раздаёт привелегии)
db.createUser({ user: 'superadmin', pwd: '123', roles: [ { role: "userAdminAnyDatabase", db: "admin" } ] });

# авторизуемся им
use admin
db.auth('superadmin', '123');
db.grantRolesToUser('superadmin',[{ role: "root", db: "admin" }])
db.adminCommand( { getParameter : 1, "saslHostName" : 1 } )

# переключаемся на нужную БД чтобы в ней создать пользователя
use biblia_production

# создаём пользователя с доступом к нужной БД и правами на чтение и запись
db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
db.auth('bibl_explorer', '123');

# ТОЛЬКО ДЛЯ ДАЛЬНЕЙШЕГО ИЗМЕНЕНИЯ ПАРОЛЯ (например после загрузки бэкапа с прода)
sudo docker exec -it mongo mongo admin
use biblia_production
db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
db.changeUserPassword("bibl_explorer", "123")

```
```ruby
# в руби-консоли создаём индексы
Verse.create_indexes
```

* Deployment instructions

git:

```shell
git add -A .
git push origin HEAD:main
./bin/bib_deploy.sh
```

```shell
ansible -m ping all
ansible -m shell -a 'uname -a' all
ansible -m setup all
```

* Usage

```shell
# console
docker exec -it bibleox bash
docker compose exec app bundle exec rails console

# Sitemap
rake g:sitemap

cd /projects/bibleox

alias nginxerrors='sudo tail -n 30 -f /var/log/nginx/error.log'
alias nginxlog='sudo tail -n 30 -f /var/log/nginx/access.log'
alias bib_update_code='git fetch && git reset --hard && git checkout origin/main'
alias bib_restart='sudo docker compose restart -t 5'
alias bib_reload='sudo rm /projects/bibleox/tmp/restart.txt && touch /projects/bibleox/tmp/restart.txt'
alias bib_log='sudo docker logs -f bibleox'
alias bib_docker='sudo docker exec -it bibleox bash'
alias bib_cache_clear='sudo rm /projects/bibleox/db/cache_search/*/*/*.json'
```

* DOMEN

зарегистрирован в reg.ru

обслуживается в https://dash.cloudflare.com/e5a70e8e380aa947cd45cdecbd410e6f/bibleox.com/dns/records

через api-cloudflare происходит автоматическое продление сертификата letsencrypt на сервере bibleox.

Если сломается, начинай диагностику с "crontab -e" под именем обычного пользователя.

* СКРИПТЫ

см. всё в ./scripts.rb

# рестарт web-сервера

touch tmp/restart.txt

# очистка поискового кэша

rm ./db/cache_search/*/*/*.json

* ПРИВЕЛЕГИИ


# !!! Стандартный набор для проверенного участника (создание страниц нужно доработать, ограничив доступ к особым полям)

```ruby
u.can!('pages_read')
# u.can!('pages_create')
u.can!('mrs_read')
u.can!('mrs_create')
```


# Если надо дать все права на одной странице и её дочерних страницах (он там может всё)

Указывается id страницы. Это даёт право редактировать статью и её меню. Те же права распространяются на все страницы, у которых родителем указана эта страница.

u.pages_owner = ['6598160bdba77200a34d0c54']
u.save


# Сброс всех привелегий

```ruby
u.update!(privs: {}, is_admin: false, pages_owner: [])
```


# Для старта:

```ruby
u.can!('pages_read')
```


# Для начала редактирования через MR:

Самая база: видеть страницы и MR

```ruby
u.can!('pages_read')
u.can!('mrs_read')

# может создавать MR
u.can!('mrs_create')
# может отклонять MR
# u.can!('mrs_reject')
# может отклонять свои MR
# u.can!('mrs_self_reject')

# может обновлять свои страницы
# u.can!('pages_self_update')
# может обновлять страницы, где принята хотя бы одна его правка
# u.can!('pages_editor_update')
# может удалять свои страницы
# u.can!('pages_self_destroy')


# может управлять менюшками (создавать, редактировать, удалять)
u.can!('menus_update')
# u.can!('menus_self_update')

# может работать со словарём
u.can!('dict_read')
u.can!('dict_create')
u.can!('dict_update')
u.can!('dict_destroy')
```

# Модератор:


```ruby
u.can!('mrs_merge')
```


# Админ:


```ruby
u.can!('super'); u.update!(is_admin: true)
```



# Греческий — библиотеки

https://github.com/skroutz/greeklish/tree/master
https://github.com/agorf/greeklish_iso843

# Поиск леммы (докер-контейнер)

https://github.com/perseids-tools/morpheus (консоль, не очень удобно)
https://github.com/perseids-tools/morpheus-perseids (консоль, удобнее)
https://github.com/perseids-tools/morpheus-perseids-api (api, норм)

онлайн api
https://morph.perseids.org/analysis/word?lang=grc&engine=morpheusgrc&word=ἐξήνεγκεν
api похуже
https://epidoc.stoa.org/gl/latest/idx-wordslemmata.html?search=κἀκ&go=search
словарь дворецкого
http://gurin.tomsknet.ru/alphaonline.html
(слово ἐκφέρω находит, в отличие от моего словаря Дворецкого)

распознавание текста в России:
https://contentai.ru/store




<entry uri="">
<dict>
<hdwd xml:lang="grc">ἄνθρωπος</hdwd>
<pofs order="3">noun</pofs>
<decl>2nd</decl>
<gend>masculine</gend>
</dict>
<infl>
<term xml:lang="grc">
<stem>ἀνθρωπ</stem>
<suff>ος</suff>
</term>
<pofs order="3">noun</pofs>
<decl>2nd</decl>
<case order="7">nominative</case>
<gend>masculine</gend>
<num>singular</num>
<stemtype>os_ou</stemtype>
</infl>
</entry>


<entry>: обозначает начало и конец записи о слове.

•  <dict>: содержит основную информацию о слове, такую как его написание, часть речи, склонение и род.

•  <hdwd>: означает заголовочное слово, то есть его лемму или словарную форму.

•  <pofs>: означает часть речи, в данном случае существительное.

•  <decl>: означает склонение, в данном случае второе.

•  <gend>: означает род, в данном случае мужской.

•  <infl>: содержит информацию об одной из форм слова, в которой оно может употребляться в предложении.

•  <term>: означает термин, то есть конкретное написание формы слова.

•  <stem>: означает основу слова, то есть его часть без окончания.

•  <suff>: означает суффикс, то есть окончание слова.

•  <case>: означает падеж, в данном случае именительный.

•  <num>: означает число, в данном случае единственное.

•  <stemtype>: означает тип основы, который определяет правила склонения слова.
