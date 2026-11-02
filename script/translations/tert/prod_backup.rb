paths = %w[iRVv_О_бегстве_во_время_гонений 2dNZ_О_покрывале_девственниц NqoW_О_посте 4xbT_О_единоженстве wvx9_О_стыдливости_De_Pudicitia тертуллиан иконы-почитают]
rows = paths.map { |pa| q = Page.find_by(lang: 'ru', path: pa); raise pa unless q; puts [q.id, q.path, q.title, q.body.size, q.updated_at].inspect; q.attributes.slice('id','path','title','title_sub','meta_desc','body','references') }
File.write('/app/tmp/tert_prod_backup.json', rows.to_json)
puts Page.exists?(lang:'ru', path:'тертуллиан'), Menu.where("title LIKE ?",'%О стыдливости%').pluck(:id,:page_id,:path).inspect
