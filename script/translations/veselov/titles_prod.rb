# Update EN titles of the 7 Veselov pages on prod (paths unchanged).
TITLES = {
  "4HgVEXyQ_Dispute_interview_the_Orthodox_Christian_with_Baptists_Salvation" => "Salvation — Dispute between Orthodox Christians and Baptists",
  "wRH9uBfa_Holy_Scripture_and_Sacred_Tradition__Dispute_interview_the_Orthodox_Christian_with_Baptists" => "Holy Scripture and Sacred Tradition — Dispute between Orthodox Christians and Baptists",
  "NVdclxkS_The_Eucharist__Dispute_interview_the_Orthodox_Christian_with_Baptists" => "The Eucharist — Dispute between Orthodox Christians and Baptists",
  "3WIGLKcD_Personal_relationship_with_Christ_of_an_Orthodox_Christian_and_a_Baptist__Dispute_interview_the_Orthodox_Christian_with_Baptists" => "Personal Relationship with Christ in an Orthodox Christian and a Baptist — Dispute between Orthodox Christians and Baptists",
  "fHMnc6di_Icon_veneration__Dispute_interview_the_Orthodox_Christian_with_Baptists" => "Icon Veneration — Dispute between Orthodox Christians and Baptists",
  "G8BmU2Xe_sacrament_of_baptism__dispute_interview_between_Orthodox_Christians_and_Baptists" => "The Sacrament of Baptism — Dispute between Orthodox Christians and Baptists",
  "SprC_Reading_Guide_for_Beginner_Orthodox_Christians" => "Reading Guide for Beginner Orthodox Christians",
}
TITLES.each do |path, title|
  pg = Page.find_by!(lang: "en", path: path)
  puts "#{pg.id}: #{pg.title.inspect} -> #{title.inspect}"
  pg.update!(title: title)
end
puts "titles done"
