OldUser.each.with_index { |o,i| o.update!(int_id: i+1) }
OldPage.each.with_index { |o,i| o.update!(int_id: i+1) }
OldVerse.each.with_index { |o,i| o.update!(int_id: i+1) }
OldBibWord.each.with_index { |o,i| o.update!(int_id: i+1) }
OldDictWord.each.with_index { |o,i| o.update!(int_id: i+1) }
OldImage.each.with_index { |o,i| o.update!(int_id: i+1) }
OldLexema.each.with_index { |o,i| o.update!(int_id: i+1) }
OldMenu.each.with_index { |o,i| o.update!(int_id: i+1) }

# USER
OldUser.each do |o|
  n = User.new
  n.attributes = o.attributes.except('_id', 'id', 'c_at', 'u_at', 'int_id')
  n.id = o.int_id
  n.created_at = o.c_at
  n.updated_at = o.u_at
  n.save
end

# PAGE
def migrate_page(old)
  return unless old
  return if Page.where(id: old.int_id).exists?
  n = Page.new
  n.attributes = old.attributes_full_names.slice(
    'page_type', 'is_bibleox', 'is_menu_icons', 'is_published', 'is_deleted', 'is_search', 'is_show_parent', 'edit_mode',
    'user_id', 'editors', 'links', 'title', 'title_sub', 'meta_desc', 'path', 'parent_id',
    'redirect_from', 'audio', 'lang', 'group_lang_id', 'body', 'verses', 'references', 'priority'
  )
  n.id = old.int_id
  if old.parent_id
    old_parent = old.parent
    if old_parent
      new_parent = Page.where(id: old_parent.int_id).first
      if new_parent.nil?
        new_parent = migrate_page(old_parent)
      end
      n.parent_id = old_parent.int_id
    end
  end
  n.user_id = User.find(old.user_id).int_id if old.user_id
  n.group_lang_id = old.group_lang_id.to_s if old.group_lang_id
  n.created_at = old.c_at
  n.updated_at = old.u_at
  ActiveRecord::Base.logger.silence do
    if n.save
      puts("saved: #{n.id}")
    else
      puts('=====ERROR=====')
      puts n.errors.messages
    end
  end
  n
end

OldPage.each { |o| migrate_page(o) }; nil

# перенос картинок
OldPage.where.not(cover: nil).each { |o|
  n = Page.find(o.int_id)
  n.update_column(:cover, o.cover_before_type_cast)
  old_path = File.join(Rails.root, 'public', "s/img/page/cover/#{o.id}")
  new_path = File.join(Rails.root, 'public', "s/img/page/cover/#{n.id}")

  # Переименовать папку
  FileUtils.mv(old_path, new_path) if Dir.exist?(old_path)
}; nil


# Сравни!
OldPage.count
Page.count

# bundle exec rails db:migrate:redo
# VERSE
OldVerse.each do |o|
  n = Verse.new
  n.attributes = o.attributes_full_names.except('_id', 'id', 'c_at', 'u_at', 'int_id', 'lang', 'z')
  n.id = o.int_id
  n.created_at = o.c_at
  # n.updated_at = o.u_at
  n.tr_code = o.lang
  n.zavet = o.z == 2
  n.lang = ::BIB_LANG_TO_LOCALE[o.lang]
  n.save
end

# bundle exec rails db:migrate:redo
OldMenu.each do |o|
  n = Menu.new
  n.attributes = o.attributes_full_names.slice('title', 'path', 'priority', 'is_gold', 'is_empty')
  n.id = o.int_id
  n.created_at = o.c_at
  n.updated_at = o.u_at

  old_parent_menu = OldMenu.where(id: o.parent_id).first if o.parent_id
  n.parent_id = old_parent_menu.int_id if old_parent_menu

  old_parent_page = OldPage.where(id: o.page_id).first
  if o.page_id.nil?
    puts '============== page_id is nil =============='
    puts o.inspect
    puts '==============--END--=============='
  elsif old_parent_page.nil?
    puts '============= PAGE NOT FOUND in DB ==============='
    puts o.inspect
    puts '=============--END--==============='
  else
    n.page_id = old_parent_page.int_id
  end
  n.save
end


# перенос счётчиков посещения страниц
Page.find_each do |n|
  o = OldPage.where(int_id: n.id).first

  if o
    old_key = "vis:#{o.id}"
    new_key = "vis:#{n.id}"

    # Получаем старое значение
    old_count = RedisConnectionPool.get(old_key)&.to_i

    if old_count&.positive?
      RedisConnectionPool.set(new_key, old_count)
      puts "Migrated #{old_count} visits: #{old_key} → #{new_key}"
      RedisConnectionPool.del(old_key)
    else
      puts "===================== NOT POSITIVE COUNTER old_key: #{old_key} ====================="
    end
  else
    puts "===================== SKIP id: #{n.id} ====================="
  end
end



OldImage.each do |old_img|
  new_img = Image.create(
    id: old_img.int_id,
    title: old_img.title,
    user_id: old_img.u_id,
    created_at: old_img.c_at,
    updated_at: old_img.u_at
  )

  if new_img.errors.any?
    puts('==========')
    puts new_img.errors.messages
  elsif old_img.simple_before_type_cast.present?
    new_img.update_column(:simple, old_img.simple_before_type_cast)

    old_path = File.join(Rails.root, 'public', "s/img/image/simple/#{old_img.id}")
    new_path = File.join(Rails.root, 'public', "s/img/image/simple/#{new_img.id}")

    # Переименовать папку
    FileUtils.mv(old_path, new_path) if Dir.exist?(old_path)
  end
end



OldLexema.each do |o|
  n = Lexema.new
  n.attributes = o.attributes_full_names.except('_id', 'id', 'c_at', 'u_at', 'int_id', 'w_d')
  n.id = o.int_id
  n.created_at = o.c_at
  n.updated_at = o.u_at
  n.save
end

OldDictWord.each do |o|
  n = DictWord.new
  n.attributes = o.attributes_full_names.except('_id', 'id', 'c_at', 'u_at', 'int_id')
  n.id = o.int_id
  n.created_at = o.c_at
  n.updated_at = o.u_at
  n.save
end

OldBibWord.each do |o|
  n = BibWord.new
  n.attributes = o.attributes_full_names.except('_id', 'id', 'c_at', 'u_at', 'int_id', 'counts_by_l')
  n.id = o.int_id
  n.counts_by_lexema = o.counts_by_l
  n.created_at = o.c_at
  n.updated_at = o.u_at
  n.save
end

# приводим в порядок ID
ActiveRecord::Base.connection.execute("SELECT setval('pages_id_seq', (SELECT MAX(id) FROM pages));")
ActiveRecord::Base.connection.execute("SELECT setval('verses_id_seq', (SELECT MAX(id) FROM verses));")
ActiveRecord::Base.connection.execute("SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));")
ActiveRecord::Base.connection.execute("SELECT setval('menus_id_seq', (SELECT MAX(id) FROM menus));")
ActiveRecord::Base.connection.execute("SELECT setval('images_id_seq', (SELECT MAX(id) FROM images));")
ActiveRecord::Base.connection.execute("SELECT setval('lexemas_id_seq', (SELECT MAX(id) FROM lexemas));")
ActiveRecord::Base.connection.execute("SELECT setval('dict_words_id_seq', (SELECT MAX(id) FROM dict_words));")
ActiveRecord::Base.connection.execute("SELECT setval('bib_words_id_seq', (SELECT MAX(id) FROM bib_words));")


# Это уже не надо
# Verse.where(tr_code: "gr-ru").find_each do |v|
#   arr_for_replace = v.data['wi']
#   next if arr_for_replace.blank?
#   arr_for_replace.each do |wi|
#     old_bib_id = wi["bw_id"]
#     next if old_bib_id.blank?
#     o = OldBibWord.where(id: old_bib_id).first
#     next if o.nil?
#     wi["bw_id"] = o.int_id
#   end
#   v.save
# end

