# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 202601233606) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "bib_words", force: :cascade do |t|
    t.integer "bw_id", null: false
    t.string "word", null: false
    t.string "dict_word"
    t.integer "counts", default: 0, null: false
    t.integer "counts_by_lexema", default: 0, null: false
    t.string "lexema"
    t.jsonb "info", default: {}, null: false
    t.jsonb "transcriptions", default: {}, null: false
    t.jsonb "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "addrs", default: [], null: false, array: true
    t.index ["bw_id"], name: "index_bib_words_on_bw_id", unique: true
    t.index ["lexema"], name: "index_bib_words_on_lexema"
    t.index ["word"], name: "index_bib_words_on_word", unique: true
  end

  create_table "books", force: :cascade do |t|
    t.text "book_color"
    t.decimal "book_number"
    t.text "short_name"
    t.text "long_name"
  end

  create_table "dict_words", force: :cascade do |t|
    t.string "dict", null: false
    t.string "word", null: false
    t.string "word_simple", null: false
    t.string "word_simple_no_endings"
    t.string "sinonim"
    t.string "lexema"
    t.string "transcription"
    t.string "transcription_lat"
    t.string "translation_short"
    t.string "translation"
    t.string "tag"
    t.text "desc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dict"], name: "index_dict_words_on_dict"
    t.index ["tag"], name: "index_dict_words_on_tag"
    t.index ["word_simple"], name: "index_dict_words_on_word_simple"
  end

  create_table "images", force: :cascade do |t|
    t.string "title"
    t.string "simple"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "h_id"
  end

  create_table "info", force: :cascade do |t|
    t.text "name"
    t.text "value"
  end

  create_table "lexemas", force: :cascade do |t|
    t.string "word", null: false
    t.string "lexema"
    t.string "lexema_clean"
    t.string "transcription"
    t.integer "counts", default: 0, null: false
    t.text "xml_doc"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lexema"], name: "index_lexemas_on_lexema"
    t.index ["word", "lexema"], name: "index_lexemas_on_word_and_lexema", unique: true
    t.index ["word"], name: "index_lexemas_on_word"
  end

  create_table "menus", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "page_id", null: false
    t.string "title", null: false
    t.string "path"
    t.boolean "is_gold", default: false
    t.boolean "is_empty", default: false
    t.integer "priority", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_menus_on_page_id"
    t.index ["parent_id"], name: "index_menus_on_parent_id"
    t.index ["path"], name: "index_menus_on_path"
  end

  create_table "pages", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "user_id"
    t.integer "editors", default: [], array: true
    t.integer "page_type", default: 1, null: false
    t.boolean "is_bibleox", default: false, null: false
    t.boolean "is_menu_icons", default: false, null: false
    t.boolean "is_published", default: false, null: false
    t.boolean "is_deleted"
    t.boolean "is_search", default: true, null: false
    t.boolean "is_show_parent", default: true, null: false
    t.integer "edit_mode", default: 1, null: false
    t.string "title", null: false
    t.string "title_sub"
    t.string "meta_desc"
    t.string "path", null: false
    t.string "path_low", null: false
    t.string "redirect_from"
    t.string "audio"
    t.string "lang", null: false
    t.text "body"
    t.text "body_rendered"
    t.jsonb "verses", default: []
    t.text "references"
    t.text "references_rendered"
    t.jsonb "body_menu", default: []
    t.jsonb "links", default: []
    t.integer "priority"
    t.string "cover"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.tsvector "body_tsvector"
    t.string "group_lang_id", null: false
    t.text "body_search"
    t.string "h_id"
    t.index ["body_tsvector"], name: "index_pages_on_body_tsvector", using: :gin
    t.index ["lang", "path"], name: "index_pages_on_lang_and_path"
    t.index ["parent_id"], name: "index_pages_on_parent_id"
    t.index ["path_low"], name: "index_pages_on_path_low", unique: true
    t.index ["redirect_from"], name: "index_pages_on_redirect_from", where: "(redirect_from IS NOT NULL)"
    t.index ["title"], name: "index_pages_on_title"
    t.index ["updated_at"], name: "index_pages_on_updated_at"
    t.index ["user_id"], name: "index_pages_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.string "name"
    t.string "password_digest"
    t.string "provider", null: false
    t.string "uid"
    t.string "api_token", null: false
    t.string "allow_ips", default: [], array: true
    t.boolean "is_admin", default: false
    t.jsonb "privs", default: {}
    t.string "pages_owner", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["username", "provider"], name: "index_users_on_username_and_provider"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "verses", force: :cascade do |t|
    t.string "tr_code", null: false
    t.string "lang", null: false
    t.string "address", null: false
    t.boolean "zavet", null: false
    t.integer "book_id", null: false
    t.string "book", null: false
    t.integer "chapter", null: false
    t.integer "line", null: false
    t.text "text", null: false
    t.text "text_search"
    t.jsonb "data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.tsvector "text_tsvector"
    t.index ["text_tsvector"], name: "index_verses_on_text_tsvector", using: :gin
    t.index ["tr_code", "book", "chapter"], name: "index_verses_on_tr_code_and_book_and_chapter"
    t.index ["tr_code", "book"], name: "index_verses_on_tr_code_and_book"
    t.index ["tr_code", "book_id", "chapter", "line"], name: "index_verses_on_tr_code_and_book_id_and_chapter_and_line", unique: true
    t.index ["tr_code", "zavet"], name: "index_verses_on_tr_code_and_zavet"
  end

  add_foreign_key "pages", "pages", column: "parent_id"
  add_foreign_key "pages", "users"
end
