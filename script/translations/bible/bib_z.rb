puts Page.where("body LIKE '%cn-ccbs%' OR \"references\" LIKE '%cn-ccbs%'").pluck(:id,:lang,:path).inspect
puts ActiveRecord::Base.connection.select_values("select cfgname from pg_ts_config").join(" ")
puts Verse.where(tr_code:'cn-ccbs').pluck(:id).minmax.inspect
