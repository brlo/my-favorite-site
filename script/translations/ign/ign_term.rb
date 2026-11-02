b=Page.where(lang:"ja").pluck(:body).join
%w[ハリストス キリスト イイスス イエス 主教 司教 輔祭 執事 司祭 長老 聖体礼儀 聖餐 致命 殉教 生神女 アガペー 愛餐].each{|w| puts "#{w}: #{b.scan(w).size}"}
z=Page.where(lang:"zh-Hans").pluck(:body).join; %w[基督 主教 司祭 辅祭 輔祭 执事 圣体 圣餐 致命 殉道].each{|w| puts "zh #{w}: #{z.scan(w).size}"}
k=Page.where(lang:"ko").pluck(:body).join; %w[그리스도 주교 사제 보제 부제 성찬 성체].each{|w| puts "ko #{w}: #{k.scan(w).size}"}
