{fuga: [4530,5312,4538], virg: [4536,5306,4547], jej: [4532,5311,4539], mono: [4534,5309,4546], pud: [4479,5310,4518]}.each do |k,ids|
  ids.zip(%w[la en ru]).each do |id,l|
    q=Page.find(id)
    File.write("tmp/tert/#{k}_#{l}.html", q.body.to_s); File.write("tmp/tert/#{k}_#{l}_refs.html", q.references.to_s)
  end
end
