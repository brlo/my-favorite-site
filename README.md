# BIBLEOX.COM

Запуск для разработки:

docker-compose up -d

Консольи разработчика:

docker exec -it bibleox rails c

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
use biblia_prod

# создаём пользователя с доступом к нужной БД и правами на чтение и запись
db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_prod" } ] });
db.auth('bibl_explorer', '123');
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
docker-compose exec app bundle exec rails console

# Sitemap
rake g:sitemap

cd /projects/bibleox

alias nginxerrors='sudo tail -n 30 -f /var/log/nginx/error.log'
alias nginxlog='sudo tail -n 30 -f /var/log/nginx/access.log'
alias bib_update_code='git fetch && git reset --hard && git checkout origin/main'
alias bib_restart='sudo docker-compose restart -t 5'
alias bib_reload='sudo rm /projects/bibleox/tmp/restart.txt && touch /projects/bibleox/tmp/restart.txt'
alias bib_log='sudo docker logs -f bibleox'
alias bib_docker='sudo docker exec -it bibleox bash'
alias bib_cache_clear='sudo rm /projects/bibleox/db/cache_search/*/*/*.json'
```

* DOMEN

зарегистрирован в reg.ru

обслуживается в https://dash.cloudflare.com/e5a70e8e380aa947cd45cdecbd410e6f/bibleox.com/dns/records

через api-cloudflare происходит автоматическое продление сертификата letsencrypt на сервере bibleox

* СКРИПТЫ

см. всё в ./scripts.rb

* ПРИВЕЛЕГИИ

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

# может обновлять свои страницы
# u.can!('pages_self_update')
# может обновлять страницы, где принята хотя бы одна его правка
# u.can!('pages_editor_update')
# может удалять свои страницы
# u.can!('pages_self_destroy')

# может управлять менюшками (создавать, редактировать, удалять)
u.can!('menus_update')
# u.can!('menus_self_update')
```

# Модератор:


```ruby
u.can!('mrs_merge')
```

# Админ:


```ruby
u.can!('super')
u.update!(is_admin: true)
```
