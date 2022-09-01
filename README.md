# BIBLEOX.COM

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
  -v /srv/mongodb:/data/db \
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

```shell
ansible -m ping all
ansible -m shell -a 'uname -a' all
ansible -m setup all
```
