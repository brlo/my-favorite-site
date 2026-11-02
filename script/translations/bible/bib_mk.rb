%w[jp-ni cn-ccbs en-nrsv ge-sch arab-avd].each do |t|
  %w[<f> <t> <e> <n> <i> <J> <S> <pb/> <br].each do |tag|
    v = Verse.where(tr_code: t).where("data->>'orig' LIKE ?", "%#{tag}%").first
    next unless v
    puts "#{t} #{tag} n=#{Verse.where(tr_code: t).where("data->>'orig' LIKE ?", "%#{tag}%").count}\n  O: #{v.data['orig'][0,250]}\n  T: #{v.text[0,250]}\n  S: #{v.text_search.to_s[0,120]}"
  end
end
